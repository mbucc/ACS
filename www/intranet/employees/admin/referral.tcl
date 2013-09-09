# /www/intranet/employees/admin/referral.tcl

ad_page_contract {

    Referral summary page - lists each employee and the number of people 
    that person referred.   

    @author mbryzek@arsdigita.com
    @creation-date Mar 2000
    @cvs-id referral.tcl,v 3.6.6.5 2000/09/22 01:38:35 kevin Exp

} {}

	

set results ""
db_foreach getreferrals "select u.user_id, u.first_names, u.last_name, x.count
	   from users u, (select info.referred_by as referring_user_id, count(1) as count
                            from im_employee_info info
                           where info.referred_by is not null
                           group by info.referred_by) x
          where u.user_id=x.referring_user_id
           order by lower(last_name), lower(first_names)" {
    append results "  <li> $last_name, $first_names: <a href=referral-details?referred_by=$user_id>[util_commify_number $count]</a>\n"
}

db_release_unused_handles

if { [empty_string_p $results] } {
    set results "  <li> There have been no referrals\n"
}

set page_title "Employee Referrals"
set context_bar [ad_context_bar_ws [list ./ Employees] "Referrals"]

set page_body "
<ul>
$results
</ul>
"

doc_return  200 text/html [im_return_template]