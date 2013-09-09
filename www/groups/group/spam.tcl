# File: /groups/group/spam.tcl
ad_page_contract {

 Purpose: this is the group spam page
    @param sendto the recipient(s)
    
    @cvs-id spam.tcl,v 3.6.2.6 2000/09/22 01:38:15 kevin Exp
} {
    sendto:multiple
}

set group_name [ns_set get $group_vars_set group_name]


ad_scope_authorize $scope all group_member none

set user_id [ad_verify_and_get_user_id]

db_1row get_user_names {
	select first_names, last_name
           from users
    where user_id = :user_id} 




set sendto_string [ad_decode $sendto "members" "Group Members" "all" "Everyone in the group" "administrators" "Group Administrators" $sendto]

set default_msg "
Dear <first_names>,

Thanks
$first_names $last_name
"

# -----------------------------------------------------------------------------

doc_return  200 text/html "
[ad_scope_header "Send Email to $sendto_string"]
[ad_scope_page_title "Email $sendto_string"]
[ad_scope_context_bar_ws_or_index [list index $group_name] [list spam-index "Email"] "$sendto_string"]

<hr>

<blockquote>

<form method=POST action=\"spam-confirm\">

[export_form_vars sendto]

<table>
<tr>
<th align=left>From:</th>
<td><input name=from_address type=text size=20 
value=\"[db_string get_email "select email from users where user_id =[ad_get_user_id]"]\">
</td>
</tr>

<tr>
<th align=left>Subject:</th>
<td><input name=subject type=text size=40></td>
</tr>

<tr>
<th align=left valign=top>Message:</th>
<td>
<textarea name=message rows=10 cols=60 wrap=soft>$default_msg</textarea>
</td>
</tr>
</table>

<center>
<p>
<input type=submit value=\"Proceed\">
</center>
</form>

<p>

<table>
<tr>
<th colspan=3>The following variables can be used to insert user/group specific data:</th> 
</tr>

<tr>
<td>&#60first_names&#62</td>
<td> = </td>
<td>User's First Name</td>
</tr>

<tr>
<td>&#60last_name&#62</td>
<td> = </td>
<td>User's Last Name</td>
</tr>

<tr>
<td>&#60email&#62</td>
<td> = </td>
<td>User's Email</td>
</tr>

<tr>
<td>&#60group_name&#62</td>
<td> = </td>
<td>Group Name</td>
</tr>
</table>
<br>
</blockquote>

[ad_scope_footer]
"







