# $Id: delete.tcl,v 3.0.4.1 2000/04/28 15:09:36 carsten Exp $
#
# /admin/users/delete.tcl
#
# present a form that will let an admin mark a user's account deleted
# (or ban the user)
#
# by philg@mit.edu late in 1998
#

set_form_variables

# user_id
# return_url (optional)

set admin_user_id [ad_verify_and_get_user_id]

if { $admin_user_id == 0 } {
    ad_returnredirect /register.tcl?return_url=[ns_urlencode "/admin/users/delete.tcl?user_id=$user_id"]
    return
}

set db [ns_db gethandle]

set selection [ns_db 1row $db "select first_names, last_name from users where user_id = $user_id"]
set_variables_after_query

ns_return 200 text/html "[ad_admin_header "Deleting $first_names $last_name"]

<h2>Deleting $first_names $last_name</h2>

<hr>

You have two options here:

<ul>

<li><a href=\"delete-2.tcl?[export_url_vars user_id return_url]\">just mark the account deleted</a> 
(as if the user him or herself had unsubscribed)

<p>

<li><form method=POST action=\"delete-2.tcl\">
[export_form_vars return_url]
<input type=submit value=\"Ban this user\">
[export_form_vars user_id]
<input type=hidden name=banned_p value=\"t\">
<br>
reason:  <input type=text size=60 name=banning_note>
</form>

</ul>


[ad_admin_footer]
"
