# /www/intranet/hours/total.tcl 

ad_page_contract {
    Shows total number of hours spent on all project

    @param on_which_table table we're viewing hours against
 
    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date Jan 2000
    @cvs-id total.tcl,v 3.7.2.6 2000/09/22 01:38:38 kevin Exp
} {
    on_which_table
}

set page_title "Hours on all projects"
set context_bar [ad_context_bar_ws "Hours on all projects"]

set page_body "
Click on a project name to see the breakdown of hours per person.
<ul>
"


set sql "
select 
    g.group_id, 
    g.group_name, 
    round(sum(h.hours)) as total_hours,
    min(h.day) as first_day, 
    max(h.day) as last_day
from user_groups g, im_hours h, im_projects p
where g.group_id = h.on_what_id
and h.on_which_table=:on_which_table
and g.group_id = p.group_id
group by g.group_id, g.group_name
order by upper(g.group_name)"

set none_found_p 1
db_foreach all_projects $sql {
    set none_found_p 0
    append page_body "<li><a href=one-project?on_what_id=$group_id&[export_url_vars on_which_table]&item=[ad_urlencode $group_name]>$group_name</A>, 
$total_hours hours between [util_AnsiDatetoPrettyDate $first_day] and [util_AnsiDatetoPrettyDate $last_day]\n";
}

if {$none_found_p == 1} {
    append page_body "<em>No time logged on any projects</em>"
}

append page_body "</UL>\n"



doc_return  200 text/html [im_return_template]
