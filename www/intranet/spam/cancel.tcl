# $Id: cancel.tcl,v 1.1.2.3 2000/04/28 15:11:11 carsten Exp $
# File: /www/intranet/spam/cancel.tcl
# Author: mbryzek@arsdigita.com, 3/15/2000
# Purpose: Cancels action to send spam

set_form_variables 0
# user_id
# return_url (optional)

if { ![exists_and_not_null return_url] } {
    set return_url [im_url_stub]
}

ad_returnredirect $return_url