ad_page_contract {
    @cvs-id user-add.tcl,v 3.5.2.3.2.4 2001/01/12 00:33:24 khy Exp
} {
}


set admin_user_id [ad_verify_and_get_user_id]

if { $admin_user_id == 0 } {
    ad_returnredirect /register.tcl?return_url=[ns_urlencode "/admin/users/"]
    return
}

append whole_page "[ad_admin_header "Add a user"]

<h2>Add a user</h2>

[ad_admin_context_bar [list "index.tcl" "Users"] "Add user"]

<hr>"



# generate unique key here so we can handle the "user hit s" case
set user_id [db_string admin_users_user_add_new_user_id_seq "
    select user_id_sequence.nextval from dual"]

append whole_page "
<form action=user-add-2 method=post>
[export_form_vars -sign user_id]
<table>
<tr><td>Email:</td><td><input type=text name=email size=20 maxlength=40></td></tr>
<tr><td>Full Name:</td><td><input type=text name=first_names size=25 maxlength=40> <input type=text name=last_name size=25 maxlength=40></td></tr>
<tr><td>Password:</td><td><input type=password name=password size=10></td></tr>
<tr><td>Password confirmation:</td><td><input type=password name=password_confirmation size=10></td></tr>
<tr><td colspan=2><blockquote><font size=-1><em>(If you don't provide a password, a random password will be generated.)</em></font></blockquote></td></tr>
</table>
<P>
<center>
<input type=submit value=\"Add User\">
</center>

</form>
<p>

[ad_admin_footer]
"



doc_return  200 text/html $whole_page
