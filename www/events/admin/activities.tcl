# event/admin/activities.tcl
# Purpose: Displays a list of current and discontinued activities.
#          Details for specific activities are one click deep.
#####

ad_page_contract {
Displays a list of current and discontinued activities.
Details for specific activities are one click deep.

@author Bryan Che (bryanche@arsdigita.com)
@cvs_id activities.tcl,v 3.8.2.6 2000/09/22 01:37:34 kevin Exp

} {
}

set user_id [ad_maybe_redirect_for_registration]


# build page to return
set whole_page ""

append whole_page "[ad_header "[ad_system_name]: Activities"]

<h2>Activities</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] "Activities"]
<hr>
<ul>
<li><a href=\"activity-add\">Add a New Activity</a> 
</ul>
<h3>Current Activities</h3>
<ul>
"

set activities_n  0
set flag 1

db_foreach all_activities "
  select a.activity_id, a.short_name, lower(a.short_name), a.available_p
    from events_activities a, user_group_map ugm
   where a.group_id = ugm.group_id
     and ugm.user_id = :user_id
union
  select activity_id, short_name, lower(short_name), available_p
    from events_activities
   where group_id is null
   order by 4 desc, 3 asc
" {
    if {$flag && $available_p == "f"} {
	append whole_page "</ul>
           <h3>Discontinued Activities</h3><ul> "
	set flag 0
    }
    append whole_page "<li>
  <a href=\"activity?activity_id=$activity_id\">$short_name</a>\n"
    incr activities_n   
}


append whole_page "</ul>"

if { $activities_n == 0 } {
    append whole_page "No current activities.\n"
}

if {$flag} {
    append whole_page "
<h3>Discontinued Activities</h3>
<ul>
<li>No discontinued activities.\n </ul>
"
}

## clean up.

append whole_page "[ad_footer] "


doc_return  200 text/html $whole_page

##### EOF
