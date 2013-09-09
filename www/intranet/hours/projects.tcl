# /www/intranet/hours/projects.tcl

ad_page_contract {
    Shows all the hours an employee has worked, organized 
    by project
    
    @param on_which_table table for which we're viewing hours
    @param user_id If specified, give them information for that user. Otherwise, send a list of users.

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000

    @cvs-id projects.tcl,v 3.6.6.6 2000/09/22 01:38:38 kevin Exp
} {
    { on_which_table }
    { user_id:integer "" }
}

if { [empty_string_p $user_id] } {
    # send them a list of users
    set page_title "View employee's hours"
    set context_bar [ad_context_bar_ws "View employee's hours"]
    set page_body "
Choose an employee to see their hours.
<ul>
"
    set rows_found_p 0

    set sql "select u.user_id, u.first_names || ' ' || u.last_name as user_name 
               from users_active u
              where exists (select 1 from im_hours where user_id = u.user_id)
              order by lower(user_name)"

    db_foreach users_who_logged_hours $sql {
        append page_body "<li><a href=projects?[export_url_vars on_which_table user_id]>$user_name</a>\n"
    } if_no_rows {
        append page_body "<em>No users found</em>"
    }

    append page_body "</ul>"

} else {
    
    if { ![db_0or1row user_name \
	    "select first_names || ' ' || last_name as user_name
               from users 
              where user_id = :user_id"] } {

        ad_return_error "User does not exist" "User #$user_id does not exist. Please back up and try again"
	return
    }
	      
    set page_title "Hours by $user_name"
    set context_bar [ad_context_bar_ws [list projects?[export_url_vars on_which_table] "View employee's hours"] "One employee"]

    # Click on a project name to see the full log for that project 
    set page_body "<ul>\n"

    set sql "
select 
    g.group_name, 
    g.group_id,
    round(sum(h.hours)) as total_hours,
    min(h.day) as first_day, 
    max(h.day) as last_day
from user_groups g, im_hours h
where g.group_id = h.on_what_id
and h.on_which_table=:on_which_table
and h.user_id = :user_id
group by g.group_name, g.group_id"

    db_foreach hours_on_project $sql {
        append page_body "<li><a href=full?on_what_id=$group_id&[export_url_vars on_which_table user_id]&date=$last_day&item=[ad_urlencode $group_name]>$group_name</a>, $total_hours hours 
between [util_AnsiDatetoPrettyDate $first_day] and [util_AnsiDatetoPrettyDate $last_day]\n"
    } if_no_rows {
        append page_body "<em>No time logged on any projects</em>"
    }
    append page_body "</ul>"
}

 

doc_return  200 text/html [im_return_template]
