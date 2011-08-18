# $Id: user-add-3.tcl,v 3.1.2.1 2000/04/28 15:09:37 carsten Exp $
set_the_usual_form_variables

# email, message, first_names, last_name, user_id


set admin_user_id [ad_verify_and_get_user_id]

if { $admin_user_id == 0 } {
    ad_returnredirect /register.tcl?return_url=[ns_urlencode "/admin/users/"]
    return
}


append whole_page "[ad_admin_header "Email sent"]

<h2>Email sent</h2>

[ad_admin_context_bar [list "index.tcl" "Users"] "New user notified"]

<hr>
"

set db [ns_db gethandle]
set admin_email [database_to_tcl_string $db "select email from 
users where user_id = $admin_user_id"]

ns_sendmail "$email" "$admin_email" "You have been added as a user to [ad_system_name] at [ad_parameter SystemUrl]" "$message"

append whole_page "
$first_names $last_name has been notified.
<p>
<ul>
<li>Return to <a href=/admin/users>user administration</a>.
<li>View admininstrative page <a href=/admin/users/one.tcl?[export_url_vars user_id]>$first_names $last_name</a>
</ul>

[ad_admin_footer]
"
ns_db releasehandle $db
ns_return 200 text/html $whole_page
