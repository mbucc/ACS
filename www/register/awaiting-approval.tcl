ad_page_contract {
    @cvs-id awaiting-approval.tcl,v 3.4.2.5 2000/09/22 01:39:13 kevin Exp
} {
    user_id:integer
}
 
set bind_vars [ad_tcl_vars_to_ns_set user_id]

if {![db_0or1row register_user_state_information "select user_state, email
from users where user_id = :user_id 
and  (user_state = 'need_admin_approv' or user_state = 'need_email_verification_and_admin_approval' or user_state = 'rejected')" -bind $bind_vars]} {
    ad_return_error "Couldn't find your record" "User id $user_id is not in the awaiting approval state.  This is probably our programming bug."
    return
}


if {![ad_parameter RegistrationRequiresApprovalP "" 0]} {
    # we are not using the "approval" system
    # they should not be in this state

    if {$user_state == "need_admin_approv"} {
	# we don't require email verification
	set new_user_state "authorized"
	db_dml register_user_state_authorized_set "update users set user_state = 'authorized' where user_id = :user_id" -bind $bind_vars
        ad_returnredirect "user-login.tcl?[export_url_vars email]"
        return
    } else {
	db_dml register_user_state_need_email_verification_set "update users set user_state = 'need_email_verification'
where user_id = :user_id" -bind -$bind_vars
        ad_returnredirect "awaiting-email-verification.tcl?[export_url_vars user_id]"
        return
    }

    # try to login again with this new state
}



doc_return  200 text/html "[ad_header "Awaiting Approval"]

<h2>Awaiting Approval</h2>

<hr>

Your registration request has been submitted 
to the [ad_system_name] administrator.   It is still
waiting approval.
<p>
Thank you.

[ad_footer]
"

