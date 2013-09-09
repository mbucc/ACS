# /www/pvt/basic-info-update.tcl

ad_page_contract {
    Displays form for currently logged in user to update his/her
    personal information

    @param return_url An optional url to redirect the user to, once the task is completed.

    @author Multiple
    @cvs-id basic-info-update.tcl,v 3.5.2.2 2000/09/22 01:39:09 kevin Exp
} {
    return_url:optional
}

set document ""

set user_id [ad_maybe_redirect_for_registration]

db_1row user_info {
    select first_names, last_name, email, url, screen_name, bio 
    from users 
    where user_id=:user_id
} 

append document "
[ad_header "Update Basic Information"]

<h2>Update Basic Information</h2>

in [ad_site_home_link]

<hr>

<form method=POST action=\"basic-info-update-2\">
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

doc_return  200 text/html $document
