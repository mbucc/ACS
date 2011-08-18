# $Id: one-project.tcl,v 3.1.4.1 2000/03/17 08:22:57 mbryzek Exp $
# File: /www/intranet/hours/one-project.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Shows hours by all users for a specific item/project
# 

set_the_usual_form_variables 
# on_what_id on_which_table
# item (optional - for UI)

set show_notes_p 1

set db [ns_db gethandle]

set page_title "Hours"
if { [exists_and_not_null item] } {
    append page_title " on $item"
}
set context_bar [ad_context_bar [list "/" Home] [list "../index.tcl" "Intranet"] [list total.tcl?[export_url_vars on_which_table] "Project hours"] "Hours on one project"]

set page_body "
Click on a person's name to see a detailed log of their hours.
<ul>
"

set selection [ns_db select $db "\
select 
    u.user_id, 
    u.first_names || ' ' || u.last_name as user_name,
    to_char(sum(h.hours),'999G999G999') as total_hours,
    min(day) as first_day,
    max(day) as last_day
from users u, im_hours h
where u.user_id = h.user_id
and h.on_what_id = $on_what_id
and h.on_which_table = '$QQon_which_table'
group by u.user_id, first_names, last_name
order by upper(user_name)"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query

    append page_body "<li><a href=full.tcl?[export_url_vars on_what_id on_which_table user_id]&date=$last_day>$user_name</A>, $total_hours hours between 
[util_AnsiDatetoPrettyDate $first_day] and 
[util_AnsiDatetoPrettyDate $last_day]\n"
}

append page_body "</ul>\n"

ns_return 200 text/html [ad_partner_return_template]