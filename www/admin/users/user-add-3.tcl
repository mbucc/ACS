ad_page_contract {
    @cvs-id user-add-3.tcl,v 3.4.2.3.2.4 2001/01/12 00:32:48 khy Exp
} {
    user_id:integer,notnull,verify
    email:notnull
    message:notnull
    first_names:notnull
    last_name:notnull
}


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


set admin_email [db_string admin_user_email "select email from 
users where user_id = :admin_user_id"]

ns_sendmail "$email" "$admin_email" "You have been added as a user to [ad_system_name] at [ad_parameter SystemUrl]" "$message"

append whole_page "
$first_names $last_name has been notified.
<p>
<ul>
<li>Return to <a href=/admin/users>user administration</a>.
<li>View admininstrative page <a href=/admin/users/one?[export_url_vars user_id]>$first_names $last_name</a>
</ul>

[ad_admin_footer]
"



doc_return  200 text/html $whole_page
