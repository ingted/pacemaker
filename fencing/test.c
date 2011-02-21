/* 
 * Copyright (C) 2009 Andrew Beekhof <andrew@beekhof.net>
 * 
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 * 
 * This software is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#include <crm_internal.h>

#include <sys/param.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <sys/utsname.h>

#include <stdlib.h>
#include <errno.h>
#include <fcntl.h>

#include <crm/crm.h>
#include <crm/msg_xml.h>
#include <crm/common/ipc.h>
#include <crm/common/cluster.h>

#include <crm/stonith-ng.h>
#include <crm/common/xml.h>
#include <crm/common/msg.h>

static struct crm_option long_options[] = {
    {"verbose",     0, 0, 'V'},
    {"version",     0, 0, '$'},
    {"help",        0, 0, '?'},
    {"passive",     0, 0, 'p'},
    
    {0, 0, 0, 0}
};

int st_opts = st_opt_sync_call;
GMainLoop *mainloop = NULL;

static void st_callback(stonith_t *st, const char *event, xmlNode *msg)
{
    crm_log_xml_notice(msg, event);
}

static gboolean timeout_handler(gpointer data)
{
    g_main_quit(mainloop);
    return FALSE;
}

int
main(int argc, char ** argv)
{
    int flag;
    int rc = 0;
    int argerr = 0;
    int option_index = 0;

    stonith_t *st = NULL;
    GHashTable *hash = NULL;

    gboolean passive_mode = FALSE;
    
    crm_log_init(NULL, LOG_INFO, TRUE, TRUE, argc, argv);
    crm_set_options("V?$p", "mode [options]", long_options,
		    "Provides a summary of cluster's current state."
		    "\n\nOutputs varying levels of detail in a number of different formats.\n");

    while (1) {
	flag = crm_get_option(argc, argv, &option_index);
	if (flag == -1)
	    break;
		
	switch(flag) {
	    case 'V':
		alter_debug(DEBUG_INC);
		cl_log_enable_stderr(1);
		break;
	    case '$':
	    case '?':
		crm_help(flag, LSB_EXIT_OK);
		break;
	    case 'p':
		passive_mode = TRUE;
		break;
	    default:
		++argerr;
		break;
	}
    }

    if (optind > argc) {
	++argerr;
    }
    
    if (argerr) {
	crm_help('?', LSB_EXIT_GENERIC);
    }

    hash = g_hash_table_new(g_str_hash, g_str_equal);
    g_hash_table_insert(hash, crm_strdup("ipaddr"), crm_strdup("localhost"));
    g_hash_table_insert(hash, crm_strdup("pcmk-portmap"), crm_strdup("some-host=pcmk-1 pcmk-3=3,4"));
    g_hash_table_insert(hash, crm_strdup("login"), crm_strdup("root"));
    g_hash_table_insert(hash, crm_strdup("identity_file"), crm_strdup("/root/.ssh/id_dsa"));
    
    crm_debug("Create");
    st = stonith_api_new();

    rc = st->cmds->connect(st, crm_system_name, NULL, NULL);
    crm_debug("Connect: %d", rc);

    rc = st->cmds->register_notification(st, T_STONITH_NOTIFY_DISCONNECT, st_callback);
    
    if(passive_mode) {
	rc = st->cmds->register_notification(st, STONITH_OP_FENCE,   st_callback);

	rc = st->cmds->register_notification(st, STONITH_OP_DEVICE_ADD, st_callback);
	rc = st->cmds->register_notification(st, STONITH_OP_DEVICE_DEL, st_callback);
	
	mainloop = g_main_new(FALSE);
	crm_info("Looking for notification");
	g_timeout_add(500*1000, timeout_handler, NULL);
	
	g_main_run(mainloop);
	
    } else {
	rc = st->cmds->register_device(st, st_opts, "test-id", "stonith-ng", "fence_virsh", hash);
	crm_debug("Register: %d", rc);
	
	rc = st->cmds->call(st, st_opts, "test-id", "list", NULL, 10);
	crm_debug("List: %d", rc);
	
	rc = st->cmds->call(st, st_opts, "test-id", "monitor", NULL, 10);
	crm_debug("Monitor: %d", rc);
	
	rc = st->cmds->call(st, st_opts, "test-id", "status", "pcmk-2", 10);
	crm_debug("Status pcmk-2: %d", rc);
	
	rc = st->cmds->call(st, st_opts, "test-id", "status", "pcmk-1", 10);
	crm_debug("Status pcmk-1: %d", rc);
	
	rc = st->cmds->fence(st, st_opts, "unknown-host", NULL, "off", 60);
	crm_debug("Fence unknown-host: %d", rc);
	
	rc = st->cmds->call(st, st_opts,  "test-id", "status", "pcmk-1", 10);
	crm_debug("Status pcmk-1: %d", rc);
	
	rc = st->cmds->fence(st, st_opts, "pcmk-1", NULL, "off", 60);
	crm_debug("Fence pcmk-1: %d", rc);
	
	rc = st->cmds->call(st, st_opts, "test-id", "status", "pcmk-1", 10);
	crm_debug("Status pcmk-1: %d", rc);
	
	rc = st->cmds->fence(st, st_opts, "pcmk-1", NULL, "on", 10);
	crm_debug("Unfence pcmk-1: %d", rc);
	
	rc = st->cmds->call(st, st_opts, "test-id", "status", "pcmk-1", 10);
	crm_debug("Status pcmk-1: %d", rc);
	
	rc = st->cmds->fence(st, st_opts, "some-host", NULL, "off", 10);
	crm_debug("Fence alias: %d", rc);
	
	rc = st->cmds->call(st, st_opts, "test-id", "status", "some-host", 10);
	crm_debug("Status alias: %d", rc);
	
	rc = st->cmds->fence(st, st_opts, "pcmk-1", NULL, "on", 10);
	crm_debug("Unfence pcmk-1: %d", rc);
	
	rc = st->cmds->remove_device(st, st_opts, "test-id");
	crm_debug("Remove test-id: %d", rc);
    }    
    
    rc = st->cmds->disconnect(st);
    crm_debug("Disconnect: %d", rc);

    crm_debug("Destroy");
    stonith_api_delete(st);
    
    return rc;
}