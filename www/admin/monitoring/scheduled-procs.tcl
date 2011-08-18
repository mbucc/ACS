# File:        scheduled-procs.tcl
# Author:      Jon Salz <jsalz@mit.edu>
# Description: Displays a list of scheduled procedures.

ReturnHeaders

ns_write "[ad_admin_header "Scheduled Procedures"]

<form>

<h2>Scheduled Procedures on [ad_system_name]</h2>

[ad_admin_context_bar [list "" "Monitoring"] "Scheduled Procedures"]
<hr>

<table>
<tr>
<th align=left bgcolor=#C0C0C0>Proc</th>
<th align=left bgcolor=#C0C0C0>Args</th>
<th align=right bgcolor=#C0C0C0>Count</th>
<th align=left bgcolor=#C0C0C0>Last Run</th>
<th align=left bgcolor=#C0C0C0>Next Run</th>
<th align=right bgcolor=#C0C0C0>Next Run In</th>
<th align=left bgcolor=#C0C0C0>Thread?</th>
<th align=left bgcolor=#C0C0C0>Once?</th>
<th align=left bgcolor=#C0C0C0>Debug?</th>
</tr>
"

set time_fmt "%m-%d %T"

set counter 0
set bgcolors { white #E0E0E0 }

proc ad_scheduled_procs_compare { a b } {
    set next_run_a [expr { [lindex $a 5] + [lindex $a 2] }]
    set next_run_b [expr { [lindex $b 5] + [lindex $b 2] }]
    if { $next_run_a < $next_run_b } {
	return -1
    } elseif { $next_run_a > $next_run_b } {
	return 1
    } else {
	return [string compare [lindex $a 3] [lindex $b 3]]
    }
}

foreach proc_info [lsort -command ad_scheduled_procs_compare [nsv_get ad_procs .]] {
    set bgcolor [lindex $bgcolors [expr { $counter % [llength $bgcolors] }]]
    incr counter

    set thread [ad_decode [lindex $proc_info 0] "t" "Yes" "No"]
    set once [ad_decode [lindex $proc_info 1] "t" "Yes" "No"]
    set interval [lindex $proc_info 2]
    set proc [lindex $proc_info 3]
    set args [lindex $proc_info 4]
    if { $args == "" } {
	set args "&nbsp;"
    }
    set time [lindex $proc_info 5]
    set count [lindex $proc_info 6]
    set debug [ad_decode [lindex $proc_info 7] "t" "Yes" "No"]
    set last_run [ad_decode $count 0 "&nbsp;" [ns_fmttime $time $time_fmt]]
    set next_run [ns_fmttime [expr { $time + $interval }] $time_fmt]
    set next_run_in "[expr { $time + $interval - [ns_time] }] s"

    ns_write "<tr>"
    foreach name { proc args } {
	ns_write "<td bgcolor=$bgcolor>[set $name]</td>"
    }
    ns_write "<td bgcolor=$bgcolor align=right>$count</td>"
    foreach name { last_run next_run } {
	ns_write "<td bgcolor=$bgcolor>[set $name]</td>"
    }
    ns_write "<td bgcolor=$bgcolor align=right>$next_run_in</td>"
    foreach name { thread once debug } {
	ns_write "<td bgcolor=$bgcolor>[set $name]</td>"
    }
    ns_write "</tr>\n"
}

ns_write "</table>

[ad_admin_footer]
"
