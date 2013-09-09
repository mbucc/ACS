# info-update-referral.tcl,v 3.5.6.5 2000/08/16 21:24:50 mbryzek Exp
#
# File: /www/intranet/employess/admin/info-referral.tcl
# Author: mbryzek@arsdigita.com, Jan 2000
# Write employee information regarding referrals to db
# /www/intranet/employees/admin/info-update-referral.tcl

ad_page_contract {
    
    @author berkeley@arsdigita.com
    @creation-date Wed Jul 12 15:16:52 2000
    @cvs-id info-update-referral.tcl,v 3.5.6.5 2000/08/16 21:24:50 mbryzek Exp
    @param employee_id The employee getting the referral
    @param user_id_from_search The user id to add
    @param return_url Option The URL to return to
} {
    employee_id
    user_id_from_search
    return_url:optional
    
}



set user_id [value_if_exists employee_id]

if { ![exists_and_not_null return_url] } {
    set return_url "view.tcl?[export_url_vars user_id]"
}

# Blank user id means no referral
if { [empty_string_p $user_id_from_search] } {
    set user_id_from_search [db_null]
}

#if it's null, we want to insert a null in the row
#if { [exists_and_not_null employee_id] && [exists_and_not_null user_id_from_search] } {

if { [exists_and_not_null employee_id] } {
    db_dml add_referral "update im_employee_info set referred_by=:user_id_from_search , referred_by_recording_user = [ad_verify_and_get_user_id] where user_id=:employee_id"
    db_release_unused_handles
}

ad_returnredirect $return_url










