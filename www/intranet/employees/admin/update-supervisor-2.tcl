# /www/intranet/employees/admin/update-supervisor-2.tcl

ad_page_contract {
    writes employee's supervisor to db
    
    @author mbryzek@arsdigita.com
    @creation-date Jan 2000
    @cvs-id update-supervisor-2.tcl,v 3.4.2.8 2000/09/16 03:15:16 jmileham Exp
    
    @param return_url Optional The url we return to
    @param dp.im_employee_info.supervisor_id The supervisor's id
    @param dp.im_employee_info.user_id The user's id
} {
    {return_url  ""}
    dp.im_employee_info.supervisor_id:naturalnum
    user_id:naturalnum,notnull
}


if {![im_is_user_site_wide_or_intranet_admin]} {
    ad_return_complaint "Forbidden" "You are not allowed to change this information"
    return
}

 
# We use data pipeline to not worry about updates vs inserts

if { ![exists_and_not_null user_id] } {
    ad_return_error "Browser broken" "Your browser is broken or our code is.  We didn't see a user_id for the user you're trying to update."
    return
}

dp_process -where_clause "user_id=:user_id" -where_bind [ns_getform]

if { [exists_and_not_null return_url] } {
    ad_returnredirect $return_url
} else {
    ad_returnredirect index
}
