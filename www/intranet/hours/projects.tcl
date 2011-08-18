# $Id: projects.tcl,v 3.1.4.1 2000/03/17 08:22:58 mbryzek Exp $
# File: /www/intranet/hours/projects.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Shows all the hours an employee has worked, organized 
# by project
# 

set_the_usual_form_variables
# on_which_table
# user_id (maybe)

# If we get a user_id, give them information for that 
# user. Otherwise, send a list of users.

set db [ns_db gethandle]

if { ![exists_and_not_null user_id] } {
    # send them a list of users
    set page_title "View employee's hours"
    set context_bar [ad_context_bar [list "/" Home] [list "../index.tcl" "Intranet"] "View employee's hours"]
    set page_body "
Choose an employee to see their hours.
<ul>
"
    set rows_found_p 0

    set selection [ns_db select $db "
select user_id, first_names || ' ' || last_name as user_name 
from users_active users
where exists (select 1 from im_hours where user_id = users.user_id)
order by lower(user_name)"]

    while {[ns_db getrow $db $selection]} {
        set rows_found_p 1
        set_variables_after_query
        append page_body "<li><a href=projects.tcl?[export_url_vars on_which_table user_id]>$user_name</a>\n"
    }
    if {$rows_found_p == 0} {
        append page_body "<em>No users found</em>"
    }

    append page_body "</ul>"

} else {

    set user_name [database_to_tcl_string $db "\
select first_names || ' ' || last_name 
from users 
where user_id = $user_id"]

    set page_title "Hours by $user_name"
    set context_bar [ad_context_bar [list "/" Home] [list "../index.tcl" "Intranet"] [list projects.tcl?[export_url_vars on_which_table] "View employee's hours"] "One employee"]

    # Click on a project name to see the full log for that project 
    set page_body "<ul>\n"

    set selection [ns_db select $db "
select 
    g.group_name, 
    g.group_id,
    round(sum(h.hours)) as total_hours,
    min(h.day) as first_day, 
    max(h.day) as last_day
from user_groups g, im_hours h
where g.group_id = h.on_what_id
and h.on_which_table='$QQon_which_table'
and h.user_id = $user_id
group by g.group_name, g.group_id"]

    set none_found_p 1
    while { [ns_db getrow $db $selection] } {
        set none_found_p 0
        set_variables_after_query

        append page_body "<li><a href=full.tcl?on_what_id=$group_id&[export_url_vars on_which_table user_id]&date=$last_day&item=[ad_urlencode $group_name]>$group_name</a>, $total_hours hours 
between [util_AnsiDatetoPrettyDate $first_day] and [util_AnsiDatetoPrettyDate $last_day]\n"
    }

    if {$none_found_p == 1} {
        append page_body "<em>No time logged on any projects</em>"
    }
    append page_body "</ul>"
}

ns_db releasehandle $db 

ns_return 200 text/html [ad_partner_return_template]
