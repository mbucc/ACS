# $Id: user-remove-cancel.tcl,v 1.1.2.4 2000/04/28 15:11:07 carsten Exp $
#
# File: /www/intranet/employess/admin/user-remove-cancel.tcl
# Author: mbryzek@arsdigita.com, 3/15/2000
# Cancels user removal by redirecting to return_url or standard employee view

set_form_variables 0
# user_id
# return_url (optional)

if { ![exists_and_not_null return_url] } {
    set return_url view.tcl?[export_url_vars user_id]
}

ad_returnredirect $return_url