# $Id: search.tcl,v 3.2.2.2 2000/04/28 15:11:06 carsten Exp $
#
# File: /www/intranet/employees/search.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Allows you to search through all employees
# 

set_the_usual_form_variables 0

# keywords

if { ![exists_and_not_null keywords] } {
    ad_returnredirect index.tcl
    return
}

set upper_keywords [string toupper $keywords]
# Convert * to oracle wild card
regsub -all {\*} $upper_keywords {%} upper_keywords

set db [ns_db gethandle]

set selection [ns_db select $db \
        "select u.last_name || ', ' || u.first_names as full_name, email, u.user_id
           from users_active u, user_group_map ugm, users_contact uc
          where upper(u.last_name||' '||u.first_names||' '||u.email||' '||uc.aim_screen_name||' '||u.screen_name) like '%[DoubleApos $upper_keywords]%'
            and u.user_id=ugm.user_id
            and ugm.group_id=[im_employee_group_id]
            and u.user_id=uc.user_id(+)
          order by lower(trim(full_name))"]

set number 0
set page_body ""
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    incr number
    if { $number == 1 && [exists_and_not_null search_type] && [string compare $search_type "Feeling Lucky"] == 0 } {
	ns_db flush $db
	ad_returnredirect ../users/view.tcl?[export_url_vars user_id]
	return
    }
    append page_body "  <li> <a href=../users/view.tcl?[export_url_vars user_id]>$full_name</a>"
    if { ![empty_string_p $email] } {
        append page_body " - <a href=\"mailto:$email\">$email</a>"
    }
    append page_body "\n"
}

ns_db releasehandle $db


if { [empty_string_p $page_body] } {
    set page_body "
<blockquote>
<b>No matches found.</b>
Look at all <a href=index.tcl>employees</a>
</blockquote>
"
} else {
    set page_body "
<b>$number [util_decode $number 1 "employee was" "employees were"] found</b>
<ul>
$page_body
</ul>

"
}


set page_title "Employee Search"
set context_bar [ad_context_bar [list "/" Home] [list ../index.tcl "Intranet"] [list index.tcl "Employees"] Search]

ns_return 200 text/html [ad_partner_return_template]
