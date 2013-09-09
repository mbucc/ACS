ad_page_contract {
    Handles users where we are waiting for email verification.
    
    @cvs-id awaiting-email-verification.tcl,v 3.5.8.6 2000/11/17 07:35:09 kevin Exp

} {
    user_id:integer
}

if { ![exists_and_not_null user_id] } {
    # Missing a user_id - ask them to login again
    ad_returnredirect index.tcl
    return
}

if {![db_0or1row register_user_state_properties {
    select user_state, email, rowid as row_id
    from users 
    where user_id = :user_id and 
    (user_state = 'need_email_verification' or user_state = 'need_email_verification_and_admin_approv')
}]} { 
    ns_log Notice "Couldn't find $user_id in /register/awaiting-email-verification.tcl"

    ad_return_error "Couldn't find your record" "User id $user_id is not found in the need email verification state."
    return
}


if ![ad_parameter RegistrationRequiresEmailVerificationP "" 0] {
    # we are not using the "email required verfication" system
    # they should not be in this state

    if {$user_state == "need_email_verification"} {
	# we don't require administration approval to get to get authorized
	set new_user_state "authorized"
	db_dml register_user_state_authorized_set "update users set 
user_state = 'authorized'
where user_id = :user_id" 
        ad_returnredirect "user-login.tcl?[export_url_vars email]"
        return
    } else {
	db_dml register_user_state_need_admin_approv_set "update users 
set user_state = 'need_admin_approv'
where user_id = :user_id" 
        ad_returnredirect "awaiting-approval.tcl?[export_url_vars user_id]"
        return
    }
}

db_release_unused_handles

# we are waiting for the user to verify their email
doc_return  200 text/html "[ad_header "Awaiting email verification"]

<h2>Awaiting email verification</h2>

<hr>

Registration information for this service has just been
sent to $email.
<p>
Please read and follow the instructions in this email.

[ad_footer]
"

# the user has to come back and activate their account
ns_sendmail  "$email" "[ad_parameter NewRegistrationEmailAddress]" "Welcome to [ad_system_name]" "To confirm your registration, please go to [ad_parameter SystemURL]/register/email-confirm.tcl?[export_url_vars row_id]"

