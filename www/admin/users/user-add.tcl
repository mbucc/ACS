# $Id: user-add.tcl,v 3.1.2.1 2000/04/28 15:09:38 carsten Exp $
set admin_user_id [ad_verify_and_get_user_id]

if { $admin_user_id == 0 } {
    ad_returnredirect /register.tcl?return_url=[ns_urlencode "/admin/users/"]
    return
}


append whole_page "[ad_admin_header "Add a user"]

<h2>Add a user</h2>

[ad_admin_context_bar [list "index.tcl" "Users"] "Add user"]

<hr>"

set db [ns_db gethandle]

# generate unique key here so we can handle the "user hit s" case
set user_id [database_to_tcl_string $db "select user_id_sequence.nextval from dual"]

append whole_page "
<form action=user-add-2.tcl method=post>
[export_form_vars user_id]
<table>
<tr><td>Email:</td><td><input type=text name=email size=20 maxlength=40></td></tr>
<tr><td>Full Name:</td><td><input type=text name=first_names size=25 maxlength=40> <input type=text name=last_name size=25 maxlength=40></td></tr>
</table>
<P>
<center>
<input type=submit value=\"Add User\">
</center>

</form>
<p>


[ad_admin_footer]
"
ns_db releasehandle $db
ns_return 200 text/html $whole_page
