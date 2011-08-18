# $Id: index.tcl,v 3.0 2000/02/06 02:44:21 ron Exp $
# File:     /address-book/index.tcl
# Date:     12/24/99
# Contact:  teadams@arsdigita.com, tarik@arsdigita.com
# Purpose:  address book main page
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)


set_the_usual_form_variables 0
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)

ad_scope_error_check user

set db [ns_db gethandle]
set user_id [ad_scope_authorize $db $scope none group_member user]

set name [address_book_name $db]

ReturnHeaders

ns_write "
[ad_scope_header "Address Book for $name" $db]
[ad_scope_page_title "Address Book for $name" $db]
[ad_scope_context_bar_ws "Address Book"]
<hr>
[ad_scope_navbar]
"

append html "
<li><a href=\"records.tcl?[export_url_scope_vars]\">View all records</a>
<p>
"

if { [ad_scope_administrator_p $db $user_id] } {
    append html "
    <li><a href=\"record-add.tcl?[export_url_scope_vars]\">Add a record</a>
    <p>
    "
}

append html "
<li>Search for a record:
<p>

<table>

<tr>
<form method=post action=record-search.tcl>
[export_form_scope_vars]
[philg_hidden_input "search_by" "last_name"]
<td align=right>
Last Name: 
</td>
<td><input type=text name=search_value size=20></td>
<td><input type=submit value=\"Search\"></td>
</form>
</tr>

<tr>
<form method=post action=record-search.tcl>
[export_form_scope_vars]
[philg_hidden_input "search_by" "first_names"]
<td align=right>
First Name:
</td>
<td><input type=text name=search_value size=20></td>
<td><input type=submit value=\"Search\"></td>
</form>
</tr>

<tr>
<form method=post action=record-search.tcl>
[export_form_scope_vars]
[philg_hidden_input "search_by" "city"]
<td align=right>
City:
</td><td><input type=text name=search_value size=20></td>
<td><input type=submit value=\"Search\"></td>
</form>
</tr>
</table>

<p>
<li><a href=\"birthdays.tcl?[export_url_scope_vars]\">View all birthdays</a>
"

ns_write "
<ul>
$html
</ul>
[ad_scope_footer]
"





