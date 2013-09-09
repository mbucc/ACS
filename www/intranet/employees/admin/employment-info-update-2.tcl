# /www/intranet/employees/admin/employment-info-update-2.tcl

ad_page_contract {
    Write employee information to db

    @author mbryzek@arsdigita.com
    @author berkeley@arsdigita.com
    @creation-date January 2000
    @cvs-id employment-info-update-2.tcl,v 3.2.2.11 2000/08/16 21:24:49 mbryzek Exp
    @param dp.im_employee_info.job_description The job description
    @param dp.im_employee_info.user_id:integer The user id
    @param dp.im_employee_info.salary.money The salary
    @param dp.im_employee_info.most_recent_review_in_folder_p A flag
    @param select_refered_by Who refered them
} {
    dp.im_employee_info.job_description
    dp.im_employee_info.user_id
    dp.im_employee_info.salary.money
    dp.im_employee_info.most_recent_review_in_folder_p
    dp.im_employee_info.start_date:optional
    dp.im_employee_info.most_recent_review:optional
    dp.im_employee_info.salary_period:optional

    {select_refered_by 0}
    start_date:array,date
    {most_recent_review:array,date ""}
}  -errors {
    start_date {must enter a start date}
    start_date:date {start_date must be a valid date}
}

set form_setid [ns_getform]    

ns_set put $form_setid dp.im_employee_info.start_date $start_date(date)

#most_recent_review isn't a necessity, while start_date is.  (which is why we 
#put start date in the -errors block
if { [info exists most_recent_review(date)] } {
    ns_set put $form_setid dp.im_employee_info.most_recent_review $most_recent_review(date)
}


set exception_count 0

set user_id ${dp.im_employee_info.user_id}

# This page is restricted to only site/intranet admins
if { ![im_is_user_site_wide_or_intranet_admin] } {
    ad_returnredirect ../
    return
}

if {[string length ${dp.im_employee_info.job_description}] > 4000} {
    incr exception_count
    append exception_text "<li>Please limit the job description to 4000 characters"
}

# Checks to see if salary entered is valid
set salary_amount ${dp.im_employee_info.salary.money}
# We allow commas in salaries
regsub -all {,} $salary_amount {} salary_amount
if {![empty_string_p $salary_amount]} {
    if { ![string is double $salary_amount] } {
	incr exception_count
	append exception_text "<li>Salary entered is not valid."
    } elseif { $salary_amount <= 0 } {
	incr exception_count
	append exception_text "<li>Salary amount $salary_amount should be greater than 0."
	
    }
}
if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}

set bind_vars [ns_set create]
ns_set put $bind_vars user_id $user_id

# get the old salary period
ns_set put $form_setid dp.im_employee_info.salary_period [im_salary_period_input]

if [catch {dp_process -where_clause "user_id=:user_id" -where_bind $bind_vars} errmsg] {
	ad_return_error "Ouch!"\
		"The database choked on your insert:
	<blockquote>
	$errmsg
	</blockquote>
		      "
}

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




