# /www/admin/users/basic-info-update.tcl
#

ad_page_contract {
    @param user_id
    @author ?
    @creation-date ?
    @cvs-id basic-info-update.tcl,v 3.2.6.3.2.4 2000/09/22 01:36:17 kevin Exp
} {
    user_id:integer,notnull
}


db_1row user_info "
select first_names, 
       last_name, 
       email, 
       url,
       screen_name
from users 
where user_id = :user_id"


append whole_page "
[ad_admin_header "Update Basic Information"]

<h2>Update Basic Information</h2>

for $first_names $last_name

<hr>

<form method=POST action=\"basic-info-update-2\">
[export_form_vars user_id]

<table>
<tr>
 <th>Name:<td><input type=text name=first_names size=20 value=\"$first_names\"> <input type=text name=last_name size=25 value=\"$last_name\">
</tr>
<tr>
 <th>email address:<td><input type=text name=email size=30 value=\"$email\">
</tr>
<tr>
 <th>Personal URL:<td><input type=text name=url size=50 value=\"$url\">
</tr>
<tr>
 <th>Screen name:<td><input type=text name=screen_name size=15 value=\"$screen_name\">
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






