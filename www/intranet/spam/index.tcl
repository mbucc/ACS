# $Id: index.tcl,v 1.2.2.2 2000/03/17 08:56:40 mbryzek Exp $

# File: /www/intranet/spam/index.tcl
# Author: mbryzek@arsdigita.com, Mar 2000
# Let's a user write spam to people in 1 group (group_id) who 
#  aren't in another (limit_to_users_in_group_id)
# We chose not to use the spam module because it's support of 
#  complex sql queries is not yet bug-free

set_form_variables 0
# group_id_list (comma separated list of group_id that users must be in)
# description (optional - replaces page_title if it's specified)

if { ![exists_and_not_null group_id_list] } {
    ad_return_complaint 1 "Missing group id(s)"
    return
}

set db [ns_db gethandle]

set exists_p [database_to_tcl_string_or_null $db \
	"select count(1) from user_groups where group_id in ($group_id_list)"]

if { $exists_p == 0 } {
    ad_return_complaint 1 "The specified group(s) (#$group_id_list) could not be found"
    return
}


set number_users_to_spam [im_spam_number_users $db $group_id_list]

if { $number_users_to_spam == 0 } {
    ad_return_complaint 1 "There are no active users to spam!"
    return
}

set from_address [database_to_tcl_string $db "select email from users where user_id='[ad_get_user_id]'"]

ns_db releasehandle $db

if { [exists_and_not_null description] } {
    set page_title $description
} else {
    set page_title "Spam users"
}

set context_bar [ad_context_bar [list "/" Home] [list ../index.tcl "Intranet"] "Spam users"]

set page_body "
<b>This email will go to $number_users_to_spam [util_decode $number_users_to_spam 1 "user" "users"]
(<a href=users-list.tcl?[export_url_vars group_id_list description return_url]>view</a>).</b>

<p> <form method=post action=confirm.tcl>
[export_form_vars group_id_list description return_url]

<table>

<tr>
<td align=right>From:</td>
<td>
<input type=text size=30 name=from_address [export_form_value from_address]></td>
</tr>

<tr>
<td align=right>Subject:</td>
<td><input name=subject type=text size=50></td>
</tr>

<tr>
<td valign=top align=right>Message:</td>
<td>
<textarea name=message rows=10 cols=70 wrap=soft></textarea>
</td>
</tr>

</table>

<center>
<input type=submit value=\"Send Email\">
</center>
</form>
"
 

ns_return 200 text/html [ad_partner_return_template]