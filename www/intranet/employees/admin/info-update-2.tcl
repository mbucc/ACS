# /www/intranet/employees/admin/info-update-2.tcl

ad_page_contract {

    Write employee information to db  

    @author berkeley@arsdigita.com
    @creation-date Wed Jul 12 15:02:13 2000
    @cvs-id info-update-2.tcl,v 3.6.2.8 2000/08/16 21:24:49 mbryzek Exp
    @param  select_referred_by The referred by select
    @param  dp.im_employee_info.user_id The user_id
    @param  dp.im_employee_info.featured_employee_blurb The blurb
    @param  dp.im_employee_info.featured_employee_approved_p Is the blurb approved?
    @param  dp.upsers.bio  biography

} {
    select_referred_by:optional
    dp.im_employee_info.user_id:naturalnum,notnull
    dp.im_employee_info.featured_employee_blurb
    dp.im_employee_info.featured_employee_approved_p
    dp.im_employee_info.salary_period:optional
    dp.users.bio

}

set exception_count 0

if { ![exists_and_not_null dp.im_employee_info.user_id] } {
    ad_return_error "Missing user id" "We weren't able to determine for what user you want information."
    return
}

set user_id ${dp.im_employee_info.user_id}

set form_setid [ns_getform]

# This page is restricted to only site/intranet admins
if { ![im_is_user_site_wide_or_intranet_admin] } {
    ad_returnredirect [im_url_stub]/employees/
    return
}

if {[string length ${dp.users.bio}] > 4000} {
    incr exception_count
    append exception_text "<li>Please limit the bio to 4000 characters"
}

if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}

# get the old salary period
ns_set put $form_setid dp.im_employee_info.salary_period [im_salary_period_input]

# Stick in the user_id for the users update
ns_set put $form_setid dp.users.user_id $user_id

dp_process -where_clause "user_id=:user_id"

if { ![exists_and_not_null return_url] } {
    set return_url "[im_url_stub]/employees/admin/view.tcl?[export_url_vars user_id]"
}

if { [exists_and_not_null select_referred_by] && $select_referred_by == "t" } {
    # Need to redirect to the user search page
    set target "[im_url_stub]/employees/admin/info-update-referral.tcl"
    set passthrough "return_url employee_id"
    set employee_id $user_id
    ad_returnredirect "[im_url_stub]/user-search.tcl?[export_url_vars passthrough target return_url employee_id]"
} else {
    ad_returnredirect $return_url
}
