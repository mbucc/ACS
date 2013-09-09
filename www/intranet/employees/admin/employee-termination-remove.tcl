# /www/intranet/employees/admin/employee-termination-remove.tcl

ad_page_contract {
    Clears out employees termination information (to bring an employee back)

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date Tue Jul 11 20:44:18 2000
    @cvs-id employee-termination-remove.tcl,v 3.2.2.5 2000/08/16 21:24:48 mbryzek Exp
    @param user_id The user thats getting the boot
    @param return_url The url to return to

} {
    user_id
    { return_url "" }
}

ad_maybe_redirect_for_registration



db_dml bringbackemployee  "update im_employee_info 
                  set termination_date='[db_null]',
                      termination_reason='[db_null]'
                where user_id=:user_id"

if { [empty_string_p $return_url] } {
    ad_returnredirect view?[export_url_vars user_id]
} else {
    ad_returnredirect $return_url
}
