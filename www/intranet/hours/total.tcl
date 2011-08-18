# $Id: total.tcl,v 3.1.4.1 2000/03/17 08:22:58 mbryzek Exp $
# File: /www/intranet/hours/total.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Shows total number of hours spent on all project
# 

set_the_usual_form_variables
# on_which_table

set page_title "Hours on all projects"
set context_bar [ad_context_bar [list "/" Home] [list "../index.tcl" "Intranet"] "Hours on all projects"]


set db [ns_db gethandle]


set page_body "
Click on a project name to breakdown of hours per person.
<ul>
"

set selection [ns_db select $db "\
select 
    g.group_id, 
    g.group_name, 
    round(sum(h.hours)) as total_hours,
    min(h.day) as first_day, 
    max(h.day) as last_day
from user_groups g, im_hours h, im_projects p
where g.group_id = h.on_what_id
and h.on_which_table='$QQon_which_table'
and g.group_id = p.group_id
group by g.group_id, g.group_name
order by upper(g.group_name)"]

set none_found_p 1
while { [ns_db getrow $db $selection] } {
    set none_found_p 0
    set_variables_after_query
    append page_body "<li><a href=one-project.tcl?on_what_id=$group_id&[export_url_vars on_which_table]&item=[ad_urlencode $group_name]>$group_name</A>, 
$total_hours hours between [util_AnsiDatetoPrettyDate $first_day] and [util_AnsiDatetoPrettyDate $last_day]\n";
}

if {$none_found_p == 1} {
    append page_body "<em>No time logged on any projects</em>"
}

append page_body "</UL>\n"

ns_return 200 text/html [ad_partner_return_template]
