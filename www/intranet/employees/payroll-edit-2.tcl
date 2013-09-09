# /www/intranet/employees/payroll-edit-2.tcl

# there are other formvars but they are collected directly by special functions(Col.*)
# 'doc_return 200 text/html "[ad_header "!" ] [create_page_variables] [ad_footer]"'
# to see them

ad_page_contract {
    Saves payroll information

    @param dp.im_employee_info.user_id:integer,notnull
    @param dp.im_employee_info.salary.money
    @param dp.im_employee_info.ss_number
    @param dp.im_employee_info.married_p
    @param dp.im_employee_info.dependant_p
    @param dp.im_employee_info.only_job_p
    @param dp.im_employee_info.head_of_household_p
    @param dp.im_employee_info.dependants
    @param birthdate
    @param first_experience

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000

    @cvs-id payroll-edit-2.tcl,v 3.3.2.12 2000/09/22 01:38:31 kevin Exp
} {
    dp.im_employee_info.user_id
    dp.im_employee_info.salary.money:optional 
    dp.im_employee_info.ss_number
    dp.im_employee_info.married_p
    dp.im_employee_info.dependant_p
    dp.im_employee_info.only_job_p
    dp.im_employee_info.head_of_household_p
    dp.im_employee_info.dependants
    { dp.im_employee_info.salary_period "" }
    { dp.im_employee_info.birthdate "" }
    { dp.im_employee_info.first_experience "" }
    {birthdate:array,date "" }
    {first_experience:array,date "" }
    
    return_url:optional
}

ad_maybe_redirect_for_registration

set exception_count 0

set user_id ${dp.im_employee_info.user_id}
set form_setid [ns_getform]

set dependant_count ${dp.im_employee_info.dependants}
if {![empty_string_p $dependant_count]} {
    if { ![string is double $dependant_count] } {
	incr exception_count
	append exception_text "<li> Number of dependants entered is not valid."
    } elseif { $dependant_count < 0 } {
	incr exception_count
	append exception_text "<li> Number of dependants cannot be less than 0."
    }
}
if {[exists_and_not_null {dp.im_employee_info.salary.money}]} {
    set salary_amount ${dp.im_employee_info.salary.money}
    regsub -all {,} $salary_amount {} salary_amount
    if {![empty_string_p $salary_amount]} {
	if { ![string is double $salary_amount] } {
	    incr exception_count
	    append exception_text "<li> Salary entered is not valid."
	} elseif { $salary_amount <=0 } {
	    incr exception_count
	    append exception_text "<li> Salary amount $$salary_amount should be greater than 0."
	}
    }
}
if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

#append html "user_id = $user_id<p>"

# can the user make administrative changes to the user's salary information?
set user_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if { !$user_admin_p } {
    ns_set delkey $form_setid dp.im_employee_info.salary
    ns_set delkey $form_setid dp.im_employee_info.salary_period
} else {
    ns_set put $form_setid dp.im_employee_info.salary_period [im_salary_period_input]
}

# This page is restricted to only site/intranet admins
if { $user_id != [ad_verify_and_get_user_id] && ![im_is_user_site_wide_or_intranet_admin] } {
    ad_returnredirect ../
    return
} 
ns_set put $form_setid {dp.im_employee_info.birthdate} $birthdate(date)
ns_set put $form_setid {dp.im_employee_info.first_experience} $first_experience(date)

if [catch { dp_process -where_clause "user_id=:user_id" } errmsg] {
    ad_return_error "Ouch!"\
		"The database choked on your insert:
	<blockquote>
	<pre>$errmsg</pre>
	</blockquote>
		      "
    return
} 

if { [exists_and_not_null return_url] } {
    ad_returnredirect $return_url
} else {
    ad_returnredirect payroll?[export_url_vars user_id]
}
