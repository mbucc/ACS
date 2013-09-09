ad_page_contract {
    Let's the user change his/her password.  Asks
    for old password, new password, and confirmation.

    @cvs-id password-update.tcl,v 3.1.6.6 2000/09/22 01:39:11 kevin Exp
} {} 


    
set user_id [ad_verify_and_get_user_id]
set bind_vars [ad_tcl_vars_to_ns_set user_id]

db_1row pvt_password_update_user_information "select first_names, 
last_name, email, url from users where user_id=:user_id" -bind $bind_vars

doc_return  200 text/html "
[ad_header "Update Password"]

<h2>Update Password</h2>

for $first_names $last_name in [ad_site_home_link]

<hr>

<form method=POST action=\"password-update-2\">

<table>
<tr>
 <th>Current Password:<td><input type=password name=password_old size=15>
</tr>
<tr>
 <th>New Password:<td><input type=password name=password_1 size=15>
</tr>
<tr>
 <th>Confirm:<td><input type=password name=password_2 size=15>
</tr>
</table>

<br>
<br>
<center>
<input type=submit value=\"Update\">
</center>

[ad_footer]
"
