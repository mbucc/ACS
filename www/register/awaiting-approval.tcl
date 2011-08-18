# $Id: awaiting-approval.tcl,v 3.2.2.1 2000/04/28 15:11:24 carsten Exp $
set_the_usual_form_variables

# user_id

set db [ns_db gethandle] 
set selection [ns_db 0or1row $db "select user_state, email
from users where user_id = $user_id 
and  (user_state = 'need_admin_approv' or user_state = 'need_email_verification_and_admin_approval' or user_state = 'rejected')"]

if { $selection == "" } {
    ad_return_error "Couldn't find your record" "User id $user_id is not in the awaiting approval state.  This is probably our programming bug."
    return
}

set_variables_after_query

if {![ad_parameter RegistrationRequiresApprovalP "" 0]} {
    # we are not using the "approval" system
    # they should not be in this state

    if {$user_state == "need_admin_approv"} {
	# we don't require email verification
	set new_user_state "authorized"
	ns_db dml $db "update users set user_state = 'authorized'
where user_id = $user_id"
        ad_returnredirect "user-login.tcl?[export_url_vars email]"
        return
    } else {
	ns_db dml $db "update users set user_state = 'need_email_verification'
where user_id = $user_id"
        ad_returnredirect "awaiting-email-verification.tcl?[export_url_vars user_id]"
        return
    }

    # try to login again with this new state
}

ns_db releasehandle $db

ns_return 200 text/html "[ad_header "Awaiting Approval"]

<h2>Awaiting Approval</h2>

<hr>

Your registration request has been submitted 
to the [ad_system_name] administrator.   It is still
waiting approval.
<p>
Thank you.

[ad_footer]
"


