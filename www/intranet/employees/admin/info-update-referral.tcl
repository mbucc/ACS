# $Id: info-update-referral.tcl,v 3.2.2.3 2000/04/28 15:11:07 carsten Exp $
#
# File: /www/intranet/employess/admin/info-referral.tcl
# Author: mbryzek@arsdigita.com, Jan 2000
# Write employee information regarding referrals to db

set_form_variables 0
# employee_id
# user_id_from_search
# return_url (optional)

set user_id [value_if_exists employee_id]

if { ![exists_and_not_null return_url] } {
    set return_url "view.tcl?[export_url_vars user_id]"
}

# Blank user id means no referral
if { [empty_string_p $user_id_from_search] } {
    set user_id_from_search null
}

if { [exists_and_not_null employee_id] && [exists_and_not_null user_id_from_search] } {
    set db [ns_db gethandle]
    ns_db dml $db "update im_employee_info set referred_by=$user_id_from_search where user_id=$employee_id"
    ns_db releasehandle $db
}

ad_returnredirect $return_url
