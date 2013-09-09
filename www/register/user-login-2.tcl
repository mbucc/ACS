ad_page_contract { 
      Verify the user's password and issue the cookie.  The following variables should be set using 
    <code>ad_set_client_property register</code>:
    <ul>
    <li>user_id
    <li>password
    <li>return_url is optional
    <li>persistent_cookie_p is optional
    </ul>

    Because some forms may still pass in the variables, we check that as well.

      @author Multiple
      @cvs-id user-login-2.tcl,v 3.7.8.8 2000/10/04 19:01:10 sklein Exp
} {
    user_id:optional,naturalnum
    password:optional
    return_url:optional
    persistent_cookie_p:optional
}

ad_handle_spammers

if { ![info exists user_id] } {
    set user_id [ad_get_client_property register user_id]
}

if { ![ info exists password] } {
    set password [ad_get_client_property register password]
}

if { ![info exists return_url] } {
    set return_url [ad_get_client_property -default [ad_pvt_home] register return_url]
}

if { ![info exists persistent_cookie_p] } {
    set persistent_cookie_p [ad_get_client_property -default "f" register persistent_cookie_p]
}

if { ![ad_check_password $user_id $password] } {
    db_release_unused_handles
    ad_returnredirect "bad-password.tcl?[export_url_vars user_id return_url]"
    return
}

# db_with_handle db 
# Log the dude in!
if { $persistent_cookie_p == "t" } {
    ad_user_login -forever t $user_id
} else {
    ad_user_login $user_id
}

ad_returnredirect $return_url

ns_conn close

# we're offline as far as the user is concerned now, but keep the
# thread alive to update the users table

# The last_visit and second_to_last_visit cookies
# were set for this session by ad_update_last_visits when
# the user first hit the site.

# Now that we know the user_id, update the database record. 

ad_update_last_visits $user_id

if {[empty_string_p [ad_second_to_last_visit_ut]]} {
    # The user came to the site with no cookies.
    # We recorded a session, but no repeat session
    # at this point.
    
    # The user subsequenty logged in.  We now
    # know that this is a repeat visit.
    ad_update_session_statistics 1 0
}

db_release_unused_handles
### EOF
