# $Id: approve-email.tcl,v 3.1.2.1 2000/04/28 15:09:35 carsten Exp $
set admin_user_id [ad_verify_and_get_user_id]

if { $admin_user_id == 0 } {
    ad_returnredirect /register.tcl?return_url=[ns_urlencode "/admin/users/awaiting-approval.tcl"]
    return
}

set_the_usual_form_variables

# user_id 

set db [ns_db gethandle]
set selection [ns_db 1row $db "select first_names || ' ' || last_name as name, user_state, email_verified_date, email from users where user_id = $user_id"]
set_variables_after_query


append whole_page "[ad_admin_header "Approving email for $name"]

<h2>Approving  email for $name</h2>

[ad_admin_context_bar [list "index.tcl" "Users"]  "Approve one"]

<hr>

"


if { $user_state == "need_email_verification" } {
    ns_db dml $db "update users 
set approved_date = sysdate, user_state = 'authorized',
approving_user = $admin_user_id
where user_id = $user_id"

    ns_sendmail  "$email" "[ad_parameter NewRegistrationEmailAddress "" [ad_system_owner]]" "Welcome to [ad_system_name]" "Your email in [ad_system_name] has been approved.  Please return to [ad_parameter SystemUrl]."

} elseif { $user_state == "need_email_verification_and_admin_approv" } {

    ns_db dml $db "update users 
set approved_date = sysdate, user_state = 'need_admin_approval',
approving_user = $admin_user_id
where user_id = $user_id"

}



append whole_page "
Done.

[ad_admin_footer]
"
ns_db releasehandle $db
ns_return 200 text/html $whole_page
