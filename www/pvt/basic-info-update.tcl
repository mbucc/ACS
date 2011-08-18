# $Id: basic-info-update.tcl,v 3.2 2000/03/10 01:12:19 mbryzek Exp $

set user_id [ad_verify_and_get_user_id]

set db [ns_db gethandle]

set selection [ns_db 1row $db "select first_names, last_name, email, url, screen_name, bio from users where user_id=$user_id"]
set_variables_after_query

ReturnHeaders 

ns_write "
[ad_header "Update Basic Information"]

<h2>Update Basic Information</h2>

in [ad_site_home_link]

<hr>

<form method=POST action=\"basic-info-update-2.tcl\">
[export_form_vars return_url]
<table>
<tr>
<tr>
 <th>Name:<td><input type=text name=first_names size=20 value=\"[philg_quote_double_quotes $first_names]\"> <input type=text name=last_name size=25 value=\"[philg_quote_double_quotes $last_name]\">
</tr>
<tr>
 <th>email address:<td><input type=text name=email size=30 value=\"[philg_quote_double_quotes $email]\">
</tr>
<tr>
 <th>Personal URL:<td><input type=text name=url size=50 value=\"[philg_quote_double_quotes $url]\"></tr>
</tr>
<tr>
 <th>screen name:<td><input type=text name=screen_name size=30 value=\"[philg_quote_double_quotes $screen_name]\">
</tr>
<tr>
<th>Biography:<td><textarea name=bio rows=10 cols=50 wrap=soft>[philg_quote_double_quotes $bio]</textarea></td>
</tr>
</table>

<br>
<br>
<center>
<input type=submit value=\"Update\">
</center>

[ad_footer]
"
