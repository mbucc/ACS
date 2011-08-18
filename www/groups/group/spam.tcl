# File: /groups/group/spam.tcl
# Date: Fri Jan 14 19:27:42 EST 2000
# Contact: ahmeds@mit.edu
# Purpose: this is the group spam page
#
# Note: group_id and group_vars_set are already set up in the environment by the ug_serve_section.
#       group_vars_set contains group related variables (group_id, group_name, group_short_name,
#       group_admin_email, group_public_url, group_admin_url, group_public_root_url, group_admin_root_url, 
#       group_type_url_p, group_context_bar_list and group_navbar_list)
#
# $Id: spam.tcl,v 3.2 2000/02/23 19:20:31 ron Exp $
# -----------------------------------------------------------------------------

set_the_usual_form_variables 0
# sendto

set group_name [ns_set get $group_vars_set group_name]

set db [ns_db gethandle]
ad_scope_authorize $db $scope all group_member none

set user_id [ad_verify_and_get_user_id]
set first_names [database_to_tcl_string $db "select first_names
                                             from users
                                             where user_id = $user_id"]
set last_name [database_to_tcl_string $db "select last_name
                                           from users
                                           where user_id = $user_id"]

set sendto_string [ad_decode $sendto "members" "Group Members" "Group Administrators"]

set default_msg "
Dear <first_names>,







Thanks
$first_names $last_name
"

# -----------------------------------------------------------------------------

ns_return 200 text/html "
[ad_scope_header "Send Email to $sendto_string" $db]
[ad_scope_page_title "Email $sendto_string" $db]
[ad_scope_context_bar_ws_or_index [list index.tcl $group_name] [list spam-index.tcl "Email"] "$sendto_string"]

<hr>

<blockquote>
<form method=POST action=\"spam-confirm.tcl\">
[export_form_vars sendto]

<table>
<tr>
<th align=left>From:</th>
<td><input name=from_address type=text size=20 
value=\"[database_to_tcl_string $db "select email from users where user_id =[ad_get_user_id]"]\">
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











