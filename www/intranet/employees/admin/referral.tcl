# $Id: referral.tcl,v 3.1.2.2 2000/03/17 07:26:09 mbryzek Exp $
#
# File: /www/intranet/employess/admin/referral.tcl
# Author: mbryzek@arsdigita.com, Mar 2000
# Referral summary page - lists each employee and the number of people 
# that person referred. 

set db [ns_db gethandle]
set selection [ns_db select $db \
	 "select u.user_id, u.first_names||' '||u.last_name as user_name, x.count 
            from (select info.referred_by, count(1) as count
                    from im_employee_info info
                   where referred_by is not null
                   group by info.referred_by) x, users_active u
           where x.referred_by=u.user_id
           order by lower(last_name), lower(first_names)"]

set results ""
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append results "  <li> $user_name: <a href=referral-details.tcl?referred_by=$user_id>[util_commify_number $count]</a>\n"
}

ns_db releasehandle $db

if { [empty_string_p $results] } {
    set results "  <li> There have been no referrals\n"
}

set page_title "Employee Referrals"
set context_bar [ad_context_bar [list "/" Home] [list ../../index.tcl "Intranet"] [list index.tcl Employees] "Referrals"]

set page_body "
<ul>
$results
</ul>
"

ns_return 200 text/html [ad_partner_return_template]