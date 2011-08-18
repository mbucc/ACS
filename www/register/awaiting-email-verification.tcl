# $Id: awaiting-email-verification.tcl,v 3.1.2.1 2000/04/28 15:11:25 carsten Exp $
set_the_usual_form_variables


# user_id

set db [ns_db gethandle] 
set selection [ns_db 0or1row $db "select user_state, email, rowid from users where user_id = $user_id and user_state = 'need_email_verification' or user_state = 'need_email_verification_and_admin_approv'"]

if { $selection == "" } {
    ns_log Notice "Couldn't find $user_id in /register/awaiting-email-verification.tcl"

    ad_return_error "Couldn't find your record" "User id $user_id is not found in the need email verification state."
    return
}

set_variables_after_query

if ![ad_parameter RegistrationRequiresEmailVerificationP "" 0] {
    # we are not using the "email required verfication" system
    # they should not be in this state

    if {$user_state == "need_email_verification"} {
	# we don't require administration approval to get to get authorized
	set new_user_state "authorized"
	ns_db dml $db "update users set user_state = 'authorized'
where user_id = $user_id"
        ad_returnredirect "user-login.tcl?[export_url_vars email]"
        return
    } else {
	ns_db dml $db "update users set user_state = 'need_admin_approv'
where user_id = $user_id"
        ad_returnredirect "awaiting_approval.tcl?[export_url_vars user_id]"
        return
    }
}

ns_db releasehandle $db

# we are waiting for the user to verify their email
ns_return 200 text/html "[ad_header "Awaiting email verification"]

<h2>Awaiting email verification</h2>

<hr>

Registration information for this service has just been
sent to $email.
<p>
Please read and follow the instructions in this email.

[ad_footer]
"

# the user has to come back and activate their account
ns_sendmail  "$email" "[ad_parameter NewRegistrationEmailAddress]" "Welcome to [ad_system_name]" "To confirm your registration, please go to [ad_parameter SystemURL]/register/email-confirm.tcl?[export_url_vars rowid]"

