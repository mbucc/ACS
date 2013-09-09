ad_page_contract {
    @cvs-id password-update.tcl,v 3.2.6.3.2.3 2000/09/22 01:36:19 kevin Exp
} {
    user_id:integer,notnull
}


db_1row user_info_by_id "select first_names, last_name, email, url from users where user_id = :user_id"


append whole_page "
[ad_admin_header "Update Password"]

<h2>Update Password</h2>

for $first_names $last_name in [ad_site_home_link]

<hr>

<form method=POST action=\"password-update-2\">

<table>
[export_form_vars user_id first_names last_name]
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

[ad_admin_footer]
"



doc_return  200 text/html $whole_page
