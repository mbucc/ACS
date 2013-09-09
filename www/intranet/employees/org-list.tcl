# /www/intranet/employees/org-list.tcl

ad_page_contract {
    by philg@mit.edu on July 6, 1999
uses CONNECT BY on the supervisor column in im_employee_info to query 
out the org chart for a company
than one person without a supervisor. We figure the Big Kahuna
is the person with no supervisor AND no subordinates
fixed a bug on 9/12/99 that caused the org chart

    @param starting_user_id 

    @author modified 1/28/2000 by mbryzek@arsdigita.com to support user groups
    @creation-date 

    @cvs-id org-list.tcl,v 3.8.2.5 2000/09/22 01:38:30 kevin Exp
} {
    { starting_user_id:integer "" }
}




set user_id [ad_maybe_redirect_for_registration]

# if starting_user_id is passed in, we use that as the starting user for the org chart



# can the user make administrative changes to this page
set user_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]

set return_url [im_url_with_query]

# Need to find the true big kahuna

# Note that the following query requires! that employees also exist in the
# im_employee_info - basically, until you say This user is supervised by nobody
# or by her, that user won't show up in the query

set big_kahuna_list [db_list kahuna_find \
	"select info.user_id 
           from im_employees_active info
          where supervisor_id is null
            and exists (select 1
                          from im_employees_active info2
                         where info2.supervisor_id = info.user_id)"]

if { [llength $big_kahuna_list] == 0 || [llength $big_kahuna_list] > 1 } {
    ad_return_error "No Big Kahuna" "<blockquote>For the org chart page to work, you need to have set up the \"who supervises whom\" relationships so that there is only one person (the CEO) who has no supervisor and no subordinates.</blockquote>"
    return
}

if { ![exists_and_not_null starting_user_id] } {
    set starting_user_id [lindex $big_kahuna_list 0]
}

# Offer admins a link to a different view
if { $user_admin_p } {
    set view_types "<a href=admin/index>Admin View</a> | " 
}

append view_types "<a href=org-chart>Org Chart</a> | "

if { $starting_user_id == [lindex $big_kahuna_list 0] } {
    append view_types "<a href=index>Standard View</a> | <b>Old Style Org Chart</b>" 
    set page_title "Org chart"
} else {
    # offer option to see full org-chart
    set starting_users_name [db_string show_starting_user \
	    "select first_names || ' ' || last_name from users where user_id=:starting_user_id"]
    append view_types "<a href=./>Standard View</a> | <a href=org-chart>Org Chart</a>"
    set page_title "Org chart starting from $starting_users_name"
}

set context_bar [ad_context_bar_ws [list ./ "Employees"] "Org Chart"]

set page_body "
<table width=100% cellpadding=0 cellspacing=0 border=0>
  <tr><td align=right>$view_types</td></tr>
</table>
<blockquote>\n"

# this is kind of inefficient in that we do a subquery to make
# sure the employee hasn't left the company, but you can't do a 
# JOIN with a CONNECT BY

#
# there's a weird case when a manager has left the company.  we can't just leave him blank because
# it screws the chart up, therefore put in a placeholder "vacant"
#

set last_level 0   ;#level of last employee
set vacant_position ""

set legacy_sql "
    select
        employee.*,
        user_group_map.group_id
    from
        (
        select 
            supervisor_id, 
            user_id, 
            replace(lpad(' ', (level - 1) * 6),' ','&nbsp;') as spacing,
            im_name_from_user_id(user_id) as employee_name,
            level
        from 
            im_employee_info
        where 
            termination_date is null
        start with 
            user_id = :starting_user_id
        connect by  
            supervisor_id = PRIOR user_id
        ) employee,
        user_group_map
    where
        employee.user_id = user_group_map.user_id(+) and
        user_group_map.group_id(+) = [im_employee_group_id]
"

set nodes_display_sql "select 
    supervisor_id, 
    user_id, 
    replace(lpad(' ', (level - 1) * 6),' ','&nbsp;') as spacing,
    im_name_from_user_id(user_id) as employee_name,
    level,
    ad_group_member_p(user_id, [im_employee_group_id]) as currently_employed_p
from 
    im_employee_info
start with 
    user_id = :starting_user_id
connect by  
    supervisor_id = PRIOR user_id"
        
db_foreach nodes_display $nodes_display_sql {
    if { $currently_employed_p == "t" } {
        if { $vacant_position != "" && $last_level < $level } {
            append page_body $vacant_position
	}
        append page_body "$spacing<a href=../users/view?[export_url_vars user_id]>$employee_name</a><br>\n"
        set vacant_position ""
    } else {
        set vacant_position $spacing
        append vacant_position "Position Vacant</i><br>\n"
    }
    set last_level $level
}

append page_body "</blockquote>\n"



doc_return  200 text/html [im_return_template]
