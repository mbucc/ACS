set user_id [ad_maybe_redirect_for_registration]

set db [ns_db gethandle]

ReturnHeaders

ns_write "[ad_header "[ad_system_name]: Activities"]

<h2>Activities</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] "Activities"]
<hr>

<h3>Current Activities</h3>
<ul>
"

#set speaker_id [events_speaker_id_for_login $db [ns_conn authuser]]

set selection [ns_db select $db "select 
a.activity_id, a.short_name, a.available_p
from events_activities a, user_groups ug, user_group_map ugm
where a.group_id = ugm.group_id
and ugm.group_id = ug.group_id
and ugm.user_id = $user_id
union
select activity_id, short_name, available_p
from events_activities
where group_id is null
order by available_p desc
"]


set i 0
set flag 1
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    
    if {$flag && $available_p == "f"} {
	ns_write "
	</ul>	
	<h3>Discontinued Activities</h3>
	<ul>
	"
	set flag 0
    }
    ns_write "<li><a href=\"activity.tcl?activity_id=$activity_id\">$short_name</a>\n"
    incr i
}

ns_write "</ul>
<a href=\"activity-add.tcl\">Add a New Activity</a>
"

if { $i == 0 } {
    ns_write "No current activities.\n"
}

if {$flag} {
    ns_write "
    <h3>Discontinued Activities</h3>
    <ul>
    <li>No discontinued activities.\n
    </ul>"
}



ns_write "
[ad_footer]
"




