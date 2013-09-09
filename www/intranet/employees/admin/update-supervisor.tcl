# update-supervisor.tcl,v 3.10.2.8 2000/09/22 01:38:35 kevin Exp
#
# File: /www/intranet/employees/admin/update-supervisor.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# present employee's current supervisor and options to update it
# 
# /www/intranet/employees/admin/update-supervisor.tcl

ad_page_contract {

    

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000
    @cvs-id update-supervisor.tcl,v 3.10.2.8 2000/09/22 01:38:35 kevin Exp
    @param user_id The user to update
    @param return_url The url we return to
} {
    user_id
    { return_url "" }
}


set caller_user_id $user_id

# get information about employee and current supervisor

db_0or1row getuserinfo "
select 
  info.*,
  supervisors.user_id as supervisor_user_id, 
  supervisors.first_names || ' ' || supervisors.last_name as supervisor_name
from im_employees_active info, users supervisors
where info.user_id = :caller_user_id
and info.supervisor_id = supervisors.user_id(+)"

if { ![info exists head_of_household_p] } {
    ad_return_error "Error" "That user doesn't exist"
    return
}


set page_title "Update supervisor for $first_names $last_name"
set context_bar [ad_context_bar_ws [list "view?user_id=$caller_user_id" "Employee information"] "Update Supervisor"]

set page_body "
[im_header]
Name:  $first_names $last_name (<a href=\"mailto:$email\">$email</a>)

<blockquote>
<p>

"

if [empty_string_p $supervisor_user_id] {
    append page_body "<i>This employee currently has no supervisor!  I hope this is the CEO.</i>\n<P>\n\n"
}

set sql "select u.user_id, u.last_name || ', ' || u.first_names as name
from im_employees_active u
where u.user_id <> :caller_user_id
order by upper(u.last_name)"

append page_body "
<form method=get action=update-supervisor-2>
[export_form_vars return_url]
<input type=hidden name=user_id value=\"$caller_user_id\">
<select name=dp.im_employee_info.supervisor_id>
<option value=\"\"> None
[db_html_select_value_options -select_option $supervisor_user_id supselectbox $sql]
</select>

<input type=submit value=\"Update\">
</form>
</blockquote>
[im_footer]
"


doc_return  200 text/html $page_body