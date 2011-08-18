#
# Issue the cookie and proceed.
#
# $Id: user-login-2.tcl,v 3.5.2.1 2000/04/28 15:11:25 carsten Exp $
#

ad_handle_spammers

set_the_usual_form_variables

# user_id, password_from_form, optionally return_url
# optionally persistent_cookie_p

if ![info exists return_url] {
    set return_url [ad_pvt_home]
}

set db [ns_db gethandle]

if { ![ad_check_password $db $user_id $password_from_form] } {
    ns_db releasehandle $db
    ad_returnredirect "bad-password.tcl?[export_url_vars user_id return_url]"
    return
}

# Log the dude in!
if { [info exists persistent_cookie_p] && $persistent_cookie_p == "t" } {
    ad_user_login -forever t $db $user_id
} else {
    ad_user_login $db $user_id
}

ad_returnredirect $return_url

ns_conn close

# we're offline as far as the user is concerned now, but keep the
# thread alive to update the users table

# The last_visit and second_to_last_visit cookies
# were set for this session by ad_update_last_visits when
# the user first hit the site.

# Now that we know the user_id, update the database record. 

ad_update_last_visits $db $user_id

if {[empty_string_p [ad_second_to_last_visit_ut]]} {
    # The user came to the site with no cookies.
    # We recorded a session, but no repeat session
    # at this point.
    
    # The user subsequenty logged in.  We now
    # know that this is a repeat visit.
    ad_update_session_statistics $db 1 0
}
