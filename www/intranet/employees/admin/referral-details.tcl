# $Id: referral-details.tcl,v 3.1.2.3 2000/04/28 15:11:07 carsten Exp $
# File: /www/intranet/employees/admin/referral-details.tcl
# Author: mbryzek@arsdigita.com, Mar 2000
# Summary view of all the people a particular employee has referred

set_form_variables 0

# referred_by

if { ![exists_and_not_null referred_by] } {
    ad_returnredirect referral.tcl
    return
}

set db [ns_db gethandle]
set user_name [database_to_tcl_string $db \
	"select first_names || ' ' || last_name from users where user_id=$referred_by"]

set page_title "Employee Referrals for $user_name"
set context_bar [ad_context_bar [list "/" Home] [list ../../index.tcl "Intranet"] [list index.tcl Employees] [list referral.tcl "Referrals"] "Referral Details"]


set selection [ns_db select $db \
	"select u.first_names||' '||u.last_name as user_name, u.user_id
           from users_active u, im_employee_info info
          where u.user_id=info.user_id
            and info.referred_by=$referred_by
          order by lower(user_name)"]


set results ""
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append results "  <li> <a href=[im_url_stub]/users/view.tcl?[export_url_vars user_id]>$user_name</a>"
}

ns_db releasehandle $db

if { [empty_string_p $results] } {
    set results "  <li> There have been no referrals\n"
}

set page_body "
<ul>
$results
</ul>
"

ns_return 200 text/html [ad_partner_return_template]
