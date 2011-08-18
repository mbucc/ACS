# $Id: become.tcl,v 3.1.4.1 2000/04/28 15:09:36 carsten Exp $
# File:     /admin/users/become.tcl
# Date:     Thu Jan 27 04:57:59 EST 2000
# Location: 42Å∞21'N 71Å∞04'W
# Location: 80 PROSPECT ST CAMBRIDGE MA 02139 USA
# Author:   mobin@mit.edu (Usman Y. Mobin)
# Purpose:  Let's administrator become any user.

set_form_variables
# user_id

set return_url [ad_pvt_home]

set db [ns_db gethandle]

# Get the password and user ID
# as of Oracle 8.1 we'll have upper(email) constrained to be unique
# in the database (could do it now with a trigger but there is really 
# no point since users only come in via this form)

set selection [ns_db 0or1row $db "select password from users where user_id=$user_id"]

if {$selection == ""} {
    ad_return_error "Couldn't find user $user_id" "Couldn't find user $user_id."
    return
}

set_variables_after_query


# just set a session cookie
set expire_state "s"


# note here that we stuff the cookie with the password from Oracle,
# NOT what the user just typed (this is because we want log in to be
# case-sensitive but subsequent comparisons are made on ns_crypt'ed 
# values, where string toupper doesn't make sense)

ad_user_login $db $user_id
ad_returnredirect $return_url
#ad_returnredirect "/cookie-chain.tcl?cookie_name=[ns_urlencode ad_auth]&cookie_value=[ad_encode_id $user_id $password]&expire_state=$expire_state&final_page=[ns_urlencode $return_url]"







