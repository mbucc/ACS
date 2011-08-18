# $Id: org-chart.tcl,v 3.3.2.1 2000/03/17 07:25:51 mbryzek Exp $
#
# File: /www/intranet/employees/org-chart.tcl
#
# by philg@mit.edu on July 6, 1999
#
# uses CONNECT BY on the supervisor column in im_employee_info to query 
# out the org chart for a company

# modified 8/6/99 by dvr@arsdigita.com to handle the case of more 
# than one person without a supervisor. We figure the Big Kahuna
# is the person with no supervisor AND no subordinates

# fixed a bug on 9/12/99 that caused the org chart

# modified 1/28/2000 by mbryzek@arsdigita.com to support user groups

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set db [ns_db gethandle]

# can the user make administrative changes to this page
set user_admin_p [im_is_user_site_wide_or_intranet_admin $db $user_id]

set return_url [ad_partner_url_with_query]

# Offer admins a link to a different view
if { $user_admin_p } {
    set view_types "<a href=admin/index.tcl>Admin View</a> | " 
}
append view_types "<b>Org Chart</b> | <a href=index.tcl>Standard View</a>"

set page_title "Org Chart"
set context_bar [ad_context_bar [list "/" Home] [list ../index.tcl "Intranet"] [list index.tcl "Employees"] "Org Chart"]

# Note that the following query requires! that employees also exist in the
# im_employee_info - basically, until you say This user is supervised by nobody
# or by her, that user won't show up in the query

set big_kahuna_list [database_to_tcl_list $db \
	"select info.user_id 
           from im_employee_info info
          where supervisor_id is null
            and exists (select 1
                          from im_employee_info
                         where supervisor_id = info.user_id)"]

if { [llength $big_kahuna_list] == 0 || [llength $big_kahuna_list] > 1 } {
    ad_return_error "No Big Kahuna" "<blockquote>For the org chart page to work, you need to have set up the \"who supervises whom\" relationships so that there is only one person (the CEO) who has no supervisor and no subordinates.</blockquote>"
    return
}

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

set sql "
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
        start with 
            user_id = [lindex $big_kahuna_list 0]
        connect by  
            supervisor_id = PRIOR user_id
        ) employee,
        user_group_map
    where
        employee.user_id = user_group_map.user_id(+) and
        user_group_map.group_id(+) = [im_employee_group_id]
"

set sql "select 
    supervisor_id, 
    user_id, 
    replace(lpad(' ', (level - 1) * 6),' ','&nbsp;') as spacing,
    im_name_from_user_id(user_id) as employee_name,
    level,
    ad_group_member_p(user_id, [im_employee_group_id]) as currently_employed_p
from 
    im_employee_info
start with 
    user_id = [lindex $big_kahuna_list 0]
connect by  
    supervisor_id = PRIOR user_id"
        
set selection [ns_db select $db $sql]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { $currently_employed_p == "t" } {
        if { $vacant_position != "" && $last_level < $level } {
            append page_body $vacant_position
	}
        append page_body "$spacing<a href=../users/view.tcl?[export_url_vars user_id]>$employee_name</a><br>\n"
        set vacant_position ""
    } else {
        set vacant_position $spacing
        append vacant_position "Position Vacant</i><br>\n"
    }
    set last_level $level
}

append page_body "</blockquote>\n"

ns_db releasehandle $db

ns_return 200 text/html [ad_partner_return_template]
