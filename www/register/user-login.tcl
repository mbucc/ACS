#
# Prompt the user for his password.
#
# $Id: user-login.tcl,v 3.4.2.3 2000/04/28 15:11:25 carsten Exp $
#

set_the_usual_form_variables

# email, return_url, password (optional)

set db [ns_db gethandle]

# Get the user ID
# as of Oracle 8.1 we'll have upper(email) constrained to be unique
# in the database (could do it now with a trigger but there is really 
# no point since users only come in via this form)
set selection [ns_db 0or1row $db "select user_id, user_state, converted_p from users where upper(email)=upper('$QQemail')"]

if {$selection == ""} {
    # not in the database
    ns_db releasehandle $db

    # Source user-new.tcl. We would redirect to it, but we don't want
    # the password exposed!
    source "[ns_url2file "/register/user-new.tcl"]"
    return
} 

set_variables_after_query

ns_db releasehandle $db

switch $user_state {
    "authorized" { # just move on } 
    "banned" { 
	ad_returnredirect "banned-user.tcl?user_id=$user_id" 
	return
    }
    "deleted" {  
	ad_returnredirect "deleted-user.tcl?user_id=$user_id" 
	return
    }
    "need_email_verification_and_admin_approv" {
	ad_returnredirect "awaiting-email-verification.tcl?user_id=$user_id"
	return
    }
    "need_admin_approv" { 
	ad_returnredirect "awaiting-approval.tcl?user_id=$user_id"
	return
    }
    "need_email_verification" {
	ad_returnredirect "awaiting-email-verification.tcl?user_id=$user_id"
	return
    }
    "rejected" {
	ad_returnredirect "awaiting-approval.tcl?user_id=$user_id"
	return
    }
    default {
	ns_log Warning "Problem with registration state machine on user-login.tcl"
	ad_return_error "Problem with login" "There was a problem authenticating the account: $user_id. Most likely, the database contains users with no user_state."
	return
    }
}


if { [ad_parameter UsersTableContainsConvertedUsersP] && $converted_p == "t" } {
    # we have a user who never actively registered; he or she was 
    # pumped into the database following a conversion, presumably
    # from a system keyed by email address (like photo.net circa 1995)
    ad_returnredirect "legacy-user.tcl?[export_url_vars user_id return_url]"
    return
}

if { [info exists password] } {
    # Continue the login process (since we already have the password).
    set password_from_form $password
    source "[ns_url2file "/register/user-login-2.tcl"]"
    return
}

set whole_page "[ad_header "Enter Password"]

<h2>Enter Password</h2>

for $email in <a href=\"index.tcl\">[ad_system_name]</a>

<hr>

<form action=\"user-login-2.tcl\" method=post>
[export_form_vars user_id return_url]
Password:  <input type=password name=password_from_form size=20>
<input type=submit value=\"Login\">

<p>

"

if [ad_parameter AllowPersistentLoginP "" 1] {
    if [ad_parameter PersistentLoginDefaultP "" 1] {
	set checked_option "CHECKED" 
    } else {
	set checked_option "" 
    }
    append whole_page "<input type=checkbox name=persistent_cookie_p value=t $checked_option> 
Remember this address and password?  
(<a href=\"explain-persistent-cookies.adp\">help</a>)"
}


append whole_page "

</form>

[ad_footer]
"

ns_return 200 text/html $whole_page

