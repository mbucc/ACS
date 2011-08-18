# $Id: update-supervisor.tcl,v 3.2.2.1 2000/03/17 07:26:11 mbryzek Exp $
#
# File: /www/intranet/employees/admin/update-supervisor.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# present employee's current supervisor and options to update it
# 

set db [ns_db gethandle]

set_the_usual_form_variables
# user_id
set caller_user_id $user_id

# get information about employee and current supervisor

set selection [ns_db 0or1row $db "
select 
  u.first_names, 
  u.last_name, 
  u.email, 
  info.*, 
  supervisors.user_id as supervisor_user_id, 
  supervisors.first_names || ' ' || supervisors.last_name as supervisor_name
from users u, im_employee_info info, users supervisors
where u.user_id = $caller_user_id
and u.user_id = info.user_id(+)
and info.supervisor_id = supervisors.user_id(+)"]

if { [empty_string_p $selection] } {
    ad_return_error "Error" "That user doesn't exist"
    return
}

set_variables_after_query

set page_title "Update supervisor for $first_names $last_name"
set context_bar [ad_context_bar [list "/" Home] [list "../../" "Intranet"] [list "view.tcl?user_id=$caller_user_id" "Employee information"] "Update Supervisor"]

ReturnHeaders
ns_write "
[ad_partner_header]
Name:  $first_names $last_name (<a href=\"mailto:$email\">$email</a>)

<blockquote>
<p>

"

if [empty_string_p $supervisor_user_id] {
    ns_write "<i>This employee currently has no supervisor!  I hope this is the CEO.</i>\n<P>\n\n"
}

set sql "select u.last_name || ', ' || u.first_names as name, u.user_id
from users u, im_employee_info info
where u.user_id <> $caller_user_id
and u.user_id = info.user_id(+)
and ad_group_member_p ( u.user_id, [im_employee_group_id] ) = 't'
order by upper(u.last_name)"


ns_write "
<form method=get action=update-supervisor-2.tcl>
<input type=hidden name=dp.im_employee_info.user_id value=\"$caller_user_id\">
<select name=dp.im_employee_info.supervisor_id>
<option value=\"\"> None
[ad_db_optionlist $db $sql $supervisor_user_id]
</select>

<input type=submit value=\"Update\">
</form>
</blockquote>
[ad_partner_footer]
"
