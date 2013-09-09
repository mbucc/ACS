# /www/intranet/employees/admin/referral-details.tcl

ad_page_contract {

    @author mbryzek@arsdigita.com
    @creation-date Mar 2000
    @cvs-id referral-details.tcl,v 3.8.2.5 2000/09/22 01:38:35 kevin Exp
    @param referred_by Who referred
} {
    { referred_by "" }
}


if { [empty_string_p $referred_by] } {
    ad_returnredirect referral
    return
}


set user_name [db_string get_full_name \
	"select first_names || ' ' || last_name from users where user_id=:referred_by"]

set page_title "Employee Referrals for $user_name"
set context_bar [ad_context_bar_ws [list ./ Employees] [list referral.tcl "Referrals"] "Referral Details"]



set results ""
db_foreach getreferral "select u.first_names||' '||u.last_name as user_name, u.user_id
           from users u, im_employee_info info
          where u.user_id=info.user_id
            and info.referred_by=$referred_by
          order by lower(user_name)" {
    append results "  <li> <a href=view?[export_url_vars user_id]>$user_name</a>"
}

db_release_unused_handles

if { [empty_string_p $results] } {
    set results "  <li> This user has not referred any other employee\n"
}

set page_body "
<ul>
$results
</ul>
"

doc_return  200 text/html [im_return_template]
