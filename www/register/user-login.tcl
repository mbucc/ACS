ad_page_contract { 
     Accepts an email from the user and branches depending on the user_state.
     If password is present, sources user-login-2 to verify the password and issue cookie.
     @author Multiple
     @cvs-id user-login.tcl,v 3.8.2.17 2000/09/22 01:39:15 kevin Exp
} {
    email:notnull
    {return_url [ad_pvt_home]}
    {password ""}
    {persistent_cookie_p "f"}
}


set upper_email [string toupper $email]

# Get the user ID
# as of Oracle 8.1 we'll have upper(email) constrained to be unique
# in the database (could do it now with a trigger but there is really 
# no point since users only come in via this form)

if {![db_0or1row user_login_user_id_from_email {
    select user_id, user_state, converted_p 
    from users 
    where upper(email) = :upper_email
}]} {

    # not in the database
    db_release_unused_handles

    # Source user-new.tcl. We would redirect to it, but we don't want
    # the password exposed!

    # psu: these unsets are needed here for a really heinous reason. we are about 
    # source user-new.tcl. this will cause havoc because user-new.tcl calls ad_page_contract,
    # which we have already done. if we don't unset this stuff here, when ad_page_contract runs
    # again it will flag everything as a double value. to stop this, i unset everything here.
    # the real fix for this is to make the code in user-new.tcl a proc.

    ad_set_client_property -persistent t register email $email
    ad_set_client_property -persistent t register return_url $return_url
    ad_set_client_property -persistent t register password $password
    ad_set_client_property -persistent t register persistent_cookie_p $persistent_cookie_p
    ad_returnredirect /register/user-new.tcl
    return
} 

db_release_unused_handles

switch $user_state {
    "authorized" {  }
    # just move on
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

if { ![empty_string_p $password] } {
    # Continue the login process (since we already have the password).
    ad_set_client_property -persistent t register user_id $user_id
    ad_set_client_property -persistent t register password $password
    ad_set_client_property -persistent t register return_url $return_url
    ad_set_client_property -persistent t register persistent_cookie_p $persistent_cookie_p
    ad_returnredirect /register/user-login-2.tcl
    return
}

set whole_page "[ad_header -focus password_form.password "Enter Password"]

<h2>Enter Password</h2>

for $email in <a href=\"index\">[ad_system_name]</a>

<hr>

<form action=\"user-login-2\" method=post name=password_form>
[export_form_vars user_id return_url]
Password:  <input type=password name=password size=20>
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
(<a href=\"explain-persistent-cookies\">help</a>)"
}

append whole_page "

</form>

[ad_footer]
"

doc_return  200 text/html $whole_page