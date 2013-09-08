# /www/admin/users/approve-email.tcl
#

ad_page_contract {
    @param user_id of user waiting for approval

    @author ?
    @creation-date ?
    @cvs-id approve-email.tcl,v 3.3.2.3.2.5 2000/09/22 01:36:17 kevin Exp

} {
    user_id:integer,notnull
}


set admin_user_id [ad_verify_and_get_user_id]

if { $admin_user_id == 0 } {
    ad_returnredirect /register.tcl?return_url=[ns_urlencode "/admin/users/view?user_state=[ns_urlencode need_admin_approv]"]
    return
}


db_1row current_user_info "select first_names || ' ' || last_name as name, user_state, email_verified_date, email from users where user_id = :user_id"

append whole_page "[ad_admin_header "Approving email for $name"]

<h2>Approving  email for $name</h2>

[ad_admin_context_bar [list "index.tcl" "Users"]  "Approve one"]

<hr>

"

if { $user_state == "need_email_verification" } {
    db_dml set_user_state_authorized "update users 
set approved_date = sysdate, user_state = 'authorized',
approving_user = :admin_user_id
where user_id = :user_id"

    ns_sendmail  "$email" "[ad_parameter NewRegistrationEmailAddress "" [ad_system_owner]]" "Welcome to [ad_system_name]" "Your email in [ad_system_name] has been approved.  Please return to [ad_parameter SystemUrl]."

} elseif { $user_state == "need_email_verification_and_admin_approv" } {

    db_dml set_user_state_need_admin_approval "update users 
set approved_date = sysdate, user_state = 'need_admin_approval',
approving_user = :admin_user_id
where user_id = :user_id"

}

append whole_page "
Done.

[ad_admin_footer]
"



doc_return  200 text/html $whole_page
