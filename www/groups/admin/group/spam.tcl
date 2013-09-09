# /groups/admin/group/spam.tcl
ad_page_contract {
    @param sendto the recipient of the spam

    @cvs-id spam.tcl,v 3.7.2.6 2000/09/22 01:38:13 kevin Exp
 Purpose:  group spam page

 Note: group_id and group_vars_set are already set up in the environment by the ug_serve_section.
       group_vars_set contains group related variables (group_id, group_name, group_short_name,
       group_admin_email, group_public_url, group_admin_url, group_public_root_url, group_admin_root_url, 
       group_type_url_p, group_context_bar_list and group_navbar_list)
} {
    sendto:notnull
}


set group_name [ns_set get $group_vars_set group_name]

if { [info exists sendto] } {
    set sendto [util_GetCheckboxValues [ns_getform] sendto ]
}


set sendto_string [join $sendto ", "] 



if { [ad_user_group_authorized_admin  [ad_verify_and_get_user_id]  $group_id] != 1 } {
    ad_return_error "Not Authorized" "You are not authorized to see this page"
    return
}



set page_html "
[ad_scope_admin_header "Send Email to $sendto_string"]
[ad_scope_admin_page_title "Email to $sendto_string "]
[ad_scope_admin_context_bar [list "spam-index" "Spam Admin"] "Spam $sendto_string"]
<hr>
"

set default_msg "
Dear <first_names>,
"

append html "
<form method=POST action=\"spam-confirm\">
[export_form_vars sendto]
<table>

<tr><th align=left>From:</th>
<td><input name=from_address type=text size=20 
value=\"[db_string get_sender_email "select email from users where user_id =[ad_get_user_id]"]\"></td></tr>

<tr><th align=left>Subject:</th><td><input name=subject type=text size=40></td></tr>

<tr><th align=left valign=top>Message:</th><td>
<textarea name=message rows=10 cols=60 wrap=soft>$default_msg</textarea>
</td></tr>

</table>

<center>

<input type=submit value=\"Proceed\">

</center>

</form>
<p>

<table >
<tr>
<th colspan=3 >The following variables can be used to be replaced with user/group specific data :
</tr>
<tr><td>
<tr><td>&#60first_names&#62 <td> = <td>User's First Name</tr>
<tr><td>&#60last_name&#62   <td> = <td>User's Last Name</tr>
<tr><td>&#60email&#62  <td> = <td> User's Email</tr>
<tr><td>&#60group_name&#62<td> = <td>Group Name</tr>
<tr><td>&#60admin_email&#62<td> = <td>Group's Administrative Email</tr>
</table>

<br>
"

doc_return  200 text/html "
$page_html

<blockquote>
$html
</blockquote>

[ad_scope_admin_footer]
"


