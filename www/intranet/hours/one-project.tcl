# /www/intranet/hours/one-project.tcl

ad_page_contract {
    Shows hours by all users for a specific item/project

    @param on_which_table table we're viewing hours against
    @param on_what_id row we're viewing hours against
    @param item used only for UI
 
    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date Jan 2000
    @cvs-id one-project.tcl,v 3.6.6.6 2000/09/22 01:38:38 kevin Exp
} {
    on_which_table
    on_what_id:integer
    { item "" }
}


set show_notes_p 1

set page_title "Hours"
if { ![empty_string_p $item] } {
    append page_title " on $item"
}
set context_bar [ad_context_bar_ws [list total?[export_url_vars on_which_table] "Project hours"] "Hours on one project"]

set page_body "
Click on a person's name to see a detailed log of their hours.
<ul>
"

set sql "
select 
    u.user_id, 
    u.first_names || ' ' || u.last_name as user_name,
    to_char(sum(h.hours),'999G999G999') as total_hours,
    min(day) as first_day,
    max(day) as last_day
from users u, im_hours h
where u.user_id = h.user_id
and h.on_what_id = :on_what_id
and h.on_which_table = :on_which_table
group by u.user_id, first_names, last_name
order by upper(user_name)"

db_foreach hours_on_one_projects $sql {

    append page_body "<li><a href=full?[export_url_vars on_what_id on_which_table user_id]&date=$last_day>$user_name</A>, $total_hours hours between 
[util_AnsiDatetoPrettyDate $first_day] and 
[util_AnsiDatetoPrettyDate $last_day]\n"
} if_no_rows {
    append page_body "<li>No hours have been logged by any user\n"
}

append page_body "</ul>\n"



doc_return  200 text/html [im_return_template]