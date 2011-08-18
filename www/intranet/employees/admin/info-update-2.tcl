# $Id: info-update-2.tcl,v 3.1.2.3 2000/04/28 15:11:07 carsten Exp $
#
# File: /www/intranet/employess/admin/info-update-2.tcl
# Author: mbryzek@arsdigita.com, Jan 2000
# Write employee information to db

set_form_variables 0
# dp variables
# select_referred_by

set exception_count 0

if { ![exists_and_not_null dp.im_employee_info.user_id] } {
    ad_return_error "Missing user id" "We weren't able to determine for what user you want information."
    return
}

set user_id ${dp.im_employee_info.user_id}

set form_setid [ns_getform]

if [catch {ns_dbformvalue [ns_conn form] start_date date start_date}] {
    incr exception_count
    append exception_text "<li>The start date is invalid"
} else {
    ns_set put $form_setid dp.im_employee_info.start_date $start_date
}

if [catch {ns_dbformvalue [ns_conn form] most_recent_review date most_recent_review}] {
    incr exception_count
    append exception_text "<li>The recent review review date is invalid"
} else {
    ns_set put $form_setid dp.im_employee_info.most_recent_review $most_recent_review
}

set db [ns_db gethandle]

# This page is restricted to only site/intranet admins
if { ![im_is_user_site_wide_or_intranet_admin $db] } {
    ad_returnredirect ../
    return
}

if {[string length ${dp.users.bio}] > 4000} {
    incr exception_count
    append exception_text "<li>Please limit the bio to 4000 characters"
}

if {[string length ${dp.im_employee_info.job_description}] > 4000} {
    incr exception_count
    append exception_text "<li>Please limit the job description to 4000 characters"
}

if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}


# get the old salary period
ns_set put $form_setid dp.im_employee_info.salary_period [im_salary_period_input]


dp_process -db $db -where_clause "user_id=$user_id"

if { ![exists_and_not_null return_url] } {
    set return_url "[im_url_stub]/employees/admin/view.tcl?[export_url_vars user_id]"
}

if { [exists_and_not_null select_referred_by] && $select_referred_by == "t" } {
    # Need to redirect to the user search page
    set target "[im_url_stub]/employees/admin/info-update-referral.tcl"
    set passthrough "return_url employee_id"
    set employee_id $user_id
    ad_returnredirect "../../user-search.tcl?[export_url_vars passthrough target return_url employee_id]"
} else {
    ad_returnredirect $return_url
}
