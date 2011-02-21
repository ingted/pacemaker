#!/bin/bash

 # Copyright (C) 2004 Andrew Beekhof <andrew@beekhof.net>
 # 
 # This program is free software; you can redistribute it and/or
 # modify it under the terms of the GNU General Public
 # License as published by the Free Software Foundation; either
 # version 2 of the License, or (at your option) any later version.
 # 
 # This software is distributed in the hope that it will be useful,
 # but WITHOUT ANY WARRANTY; without even the implied warranty of
 # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 # General Public License for more details.
 # 
 # You should have received a copy of the GNU General Public
 # License along with this library; if not, write to the Free Software
 # Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 #
if [ -x /usr/bin/valgrind ]; then
    export G_SLICE=always-malloc
    VALGRIND_CMD="valgrind -q --show-reachable=no --leak-check=full --trace-children=no --time-stamp=yes --num-callers=20 --suppressions=./ptest.supp"
fi

. regression.core.sh
io_dir=test06

create_mode="true"
echo Generating test outputs for these tests...
# do_test
echo Done.
echo ""

echo Performing the following tests...
create_mode="false"

echo ""
do_test simple1 "Offline     "
do_test simple2 "Start       "
do_test simple3 "Start 2     "
do_test simple4 "Start Failed"
do_test simple6 "Stop Start  "
do_test simple7 "Shutdown    "
#do_test simple8 "Stonith	"
#do_test simple9 "Lower version"
#do_test simple10 "Higher version"
do_test simple11 "Priority (ne)"
do_test simple12 "Priority (eq)"
do_test simple8 "Stickiness"

echo ""
do_test params-0 "Params: No change"
do_test params-1 "Params: Changed"
do_test params-2 "Params: Resource definition"
do_test params-4 "Params: Reload"
do_test novell-251689 "Resource definition change + target_role=stopped"

echo ""
do_test orphan-0 "Orphan ignore"
do_test orphan-1 "Orphan stop"

echo ""
do_test target-0 "Target Role : baseline"
do_test target-1 "Target Role : test"

echo ""
do_test date-1 "Dates" -d "2005-020"
do_test date-2 "Date Spec - Pass" -d "2005-020T12:30"
do_test date-3 "Date Spec - Fail" -d "2005-020T11:30"
do_test probe-0 "Probe (anon clone)"
do_test probe-1 "Pending Probe"
do_test standby "Standby"
do_test comments "Comments"

echo ""
do_test rsc_dep1 "Must not     "
do_test rsc_dep3 "Must         "
do_test rsc_dep5 "Must not 3   "
do_test rsc_dep7 "Must 3       "
do_test rsc_dep10 "Must (but cant)"
do_test rsc_dep2  "Must (running) "
do_test rsc_dep8  "Must (running : alt) "
do_test rsc_dep4  "Must (running + move)"
do_test asymmetric "Asymmetric - require explicit location constraints"

echo ""
do_test order1 "Order start 1     "
do_test order2 "Order start 2     "
do_test order3 "Order stop	  "
do_test order4 "Order (multiple)  "
do_test order5 "Order (move)  "
do_test order6 "Order (move w/ restart)  "
do_test order7 "Order (manditory)  "
do_test order-optional "Order (score=0)  "
do_test order-required "Order (score=INFINITY)  "

echo ""
do_test coloc-loop "Colocation - loop"
do_test coloc-many-one "Colocation - many-to-one"
do_test coloc-list "Colocation - many-to-one with list"
do_test coloc-group "Colocation - groups"
do_test coloc-slave-anti "Anti-colocation with slave shouldn't prevent master colocation"

#echo ""
#do_test agent1 "version: lt (empty)"
#do_test agent2 "version: eq	"
#do_test agent3 "version: gt	"

echo ""
do_test attrs1 "string: eq (and)     "
do_test attrs2 "string: lt / gt (and)"
do_test attrs3 "string: ne (or)      "
do_test attrs4 "string: exists       "
do_test attrs5 "string: not_exists   "
do_test attrs6 "is_dc: true          "
do_test attrs7 "is_dc: false         "
do_test attrs8 "score_attribute      "

echo ""
do_test mon-rsc-1 "Schedule Monitor - start"
do_test mon-rsc-2 "Schedule Monitor - move "
do_test mon-rsc-3 "Schedule Monitor - pending start     "
do_test mon-rsc-4 "Schedule Monitor - move/pending start"

echo ""
do_test rec-rsc-0 "Resource Recover - no start     "
do_test rec-rsc-1 "Resource Recover - start        "
do_test rec-rsc-2 "Resource Recover - monitor      "
do_test rec-rsc-3 "Resource Recover - stop - ignore"
do_test rec-rsc-4 "Resource Recover - stop - block "
do_test rec-rsc-5 "Resource Recover - stop - fence "
do_test rec-rsc-6 "Resource Recover - multiple - restart"
do_test rec-rsc-7 "Resource Recover - multiple - stop   "
do_test rec-rsc-8 "Resource Recover - multiple - block  "
do_test rec-rsc-9 "Resource Recover - group/group"

echo ""
do_test quorum-1 "No quorum - ignore"
do_test quorum-2 "No quorum - freeze"
do_test quorum-3 "No quorum - stop  "
do_test quorum-4 "No quorum - start anyway"
do_test quorum-5 "No quorum - start anyway (group)"
do_test quorum-6 "No quorum - start anyway (clone)"

echo ""
do_test rec-node-1 "Node Recover - Startup   - no fence"
do_test rec-node-2 "Node Recover - Startup   - fence   "
do_test rec-node-3 "Node Recover - HA down   - no fence"
do_test rec-node-4 "Node Recover - HA down   - fence   "
do_test rec-node-5 "Node Recover - CRM down  - no fence"
do_test rec-node-6 "Node Recover - CRM down  - fence   "
do_test rec-node-7 "Node Recover - no quorum - ignore  "
do_test rec-node-8 "Node Recover - no quorum - freeze  "
do_test rec-node-9 "Node Recover - no quorum - stop    "
do_test rec-node-10 "Node Recover - no quorum - stop w/fence"
do_test rec-node-11 "Node Recover - CRM down w/ group - fence   "
do_test rec-node-12 "Node Recover - nothing active - fence   "
do_test rec-node-13 "Node Recover - failed resource + shutdown - fence   "
do_test rec-node-15 "Node Recover - unknown lrm section"
do_test rec-node-14 "Serialize all stonith's"

echo ""
do_test multi1 "Multiple Active (stop/start)"

echo ""
do_test migrate-1 "Migrate (migrate)"
do_test migrate-2 "Migrate (stable)"
do_test migrate-3 "Migrate (failed migrate_to)"
do_test migrate-4 "Migrate (failed migrate_from)"
do_test novell-252693 "Migration in a stopping stack"
do_test novell-252693-2 "Migration in a starting stack"
do_test novell-252693-3 "Non-Migration in a starting and stopping stack"
do_test bug-1820 "Migration in a group"
do_test bug-1820-1 "Non-migration in a group"

#echo ""
#do_test complex1 "Complex	"

echo ""
do_test group1 "Group		"
do_test group2 "Group + Native	"
do_test group3 "Group + Group	"
do_test group4 "Group + Native (nothing)"
do_test group5 "Group + Native (move)   "
do_test group6 "Group + Group (move)    "
do_test group7 "Group colocation"
do_test group13 "Group colocation (cant run)"
do_test group8 "Group anti-colocation"
do_test group9 "Group recovery"
do_test group10 "Group partial recovery"
do_test group11 "Group target_role"
do_test group14 "Group stop (graph terminated)"
do_test group15 "-ve group colocation"
do_test bug-1573 "Partial stop of a group with two children"
do_test bug-1718 "Mandatory group ordering - Stop group_FUN"

echo ""
do_test clone-anon-probe-1 "Probe the correct (anonymous) clone instance for each node"
do_test clone-anon-probe-2 "Avoid needless re-probing of anonymous clones"
do_test inc0 "Incarnation start" 
do_test inc1 "Incarnation start order" 
do_test inc2 "Incarnation silent restart, stop, move"
do_test inc3 "Inter-incarnation ordering, silent restart, stop, move"
do_test inc4 "Inter-incarnation ordering, silent restart, stop, move (ordered)"
do_test inc5 "Inter-incarnation ordering, silent restart, stop, move (restart 1)"
do_test inc6 "Inter-incarnation ordering, silent restart, stop, move (restart 2)"
do_test inc7 "Clone colocation"
do_test inc8 "Clone anti-colocation"
#do_test inc9 "Non-unique clone"
do_test inc10 "Non-unique clone (stop)"
do_test inc11 "Primitive colocation with clones" 
do_test inc12 "Clone shutdown" 
do_test cloned-group "Make sure only the correct number of cloned groups are started"
do_test clone-no-shuffle "Dont prioritize allocation of instances that must be moved"

echo ""
do_test master-0 "Stopped -> Slave"
do_test master-1 "Stopped -> Promote"
do_test master-2 "Stopped -> Promote : notify"
do_test master-3 "Stopped -> Promote : master location"
do_test master-4 "Started -> Promote : master location"
do_test master-5 "Promoted -> Promoted"
do_test master-6 "Promoted -> Promoted (2)"
do_test master-7 "Promoted -> Fenced"
do_test master-8 "Promoted -> Fenced -> Moved"
do_test master-9 "Stopped + Promotable + No quorum"
do_test master-10 "Stopped -> Promotable : notify with monitor"
do_test master-11 "Stopped -> Promote : colocation"
do_test novell-239082 "Demote/Promote ordering"
do_test novell-239087 "Stable master placement"
do_test master-12 "Promotion based solely on rsc_location constraints"
do_test master-13 "Include preferences of colocated resources when placing master"
do_test master-demote "Ordering when actions depends on demoting a slave resource" 
do_test master-ordering "Prevent resources from starting that need a master"
do_test bug-1765 "Master-Master Colocation (dont stop the slaves)"
do_test master-group "Promotion of cloned groups"
do_test bug-lf-1852 "Don't shuffle master/slave instances unnecessarily"
do_test master-failed-demote "Dont retry failed demote actions"
do_test master-failed-demote-2 "Dont retry failed demote actions (notify=false)"
do_test master-depend "Ensure resources that depend on the master don't get allocated until the master does"

echo ""
do_test managed-0 "Managed (reference)"
do_test managed-1 "Not managed - down "
do_test managed-2 "Not managed - up   "

echo ""
do_test interleave-0 "Interleave (reference)"
do_test interleave-1 "coloc - not interleaved"
do_test interleave-2 "coloc - interleaved   "
do_test interleave-3 "coloc - interleaved (2)"
do_test interleave-pseudo-stop "Interleaved clone during stonith"
do_test interleave-stop "Interleaved clone during stop"
do_test interleave-restart "Interleaved clone during dependency restart"

echo ""
do_test notify-0 "Notify reference"
do_test notify-1 "Notify simple"
do_test notify-2 "Notify simple, confirm"
do_test notify-3 "Notify move, confirm"
do_test novell-239079 "Notification priority"
#do_test notify-2 "Notify - 764"

echo ""
do_test 594 "OSDL #594"
do_test 662 "OSDL #662"
do_test 696 "OSDL #696"
do_test 726 "OSDL #726"
do_test 735 "OSDL #735"
do_test 764 "OSDL #764"
do_test 797 "OSDL #797"
do_test 829 "OSDL #829"
do_test 994 "OSDL #994"
do_test 994-2 "OSDL #994 - with a dependant resource"
do_test 1360 "OSDL #1360 - Clone stickiness"
do_test 1484 "OSDL #1484 - on_fail=stop"
do_test 1494 "OSDL #1494 - Clone stability"
do_test unrunnable-1 "Unrunnable"
do_test stonith-0 "Stonith loop - 1"
do_test stonith-1 "Stonith loop - 2"
do_test stonith-2 "Stonith loop - 3"
do_test bug-1572-1 "Recovery of groups depending on master/slave"
do_test bug-1572-2 "Recovery of groups depending on master/slave when the master is never re-promoted"
do_test bug-1685 "Depends-on-master ordering"
do_test bug-1822 "Dont promote partially active groups"
do_test bug-pm-11 "New resource added to a m/s group"
do_test bug-pm-12 "Recover only the failed portion of a cloned group"
do_test bug-n-387749 "Don't shuffle clone instances"
do_test bug-n-385265 "Don't ignore the failure stickiness of group children - resource_idvscommon should stay stopped"
do_test bug-n-385265-2 "Ensure groups are migrated instead of remaining partially active on the current node"
do_test bug-lf-1920 "Correctly handle probes that find active resources"

echo ""

test_results