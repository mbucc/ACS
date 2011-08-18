# $Id: record-delete.tcl,v 3.0 2000/02/06 02:44:21 ron Exp $
# File:     /address-book/record-delete.tcl
# Date:     12/24/99
# Contact:  teadams@arsdigita.com, tarik@arsdigita.com
# Purpose:  deletes address book record
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

set_the_usual_form_variables 0
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)
# address_book_id, maybe return_url

ad_scope_error_check user
set db [ns_db gethandle]
ad_scope_authorize $db $scope none group_admin user

set selection [ns_db 1row $db "
select * from
address_book where address_book_id = $address_book_id"]
set_variables_after_query

if { ![info exists contact_info_only] } {
    set contact_info_only "f"
}

ns_return 200 text/html  "
[ad_scope_header "Delete $first_names $last_name" $db]
[ad_scope_page_title "Delete $first_names $last_name" $db ]
[ad_scope_context_bar_ws [list "index.tcl?[export_url_scope_vars return_url]" "Address book"] "Delete record"]
<hr>
[ad_scope_navbar]
<form method=post action=\"record-delete-2.tcl\">
[export_form_scope_vars address_book_id return_url]
Are you sure you want to delete the record for $first_names $last_name?
<p>
<center>
<table>
<tr><td>
<input type=submit name=yes_submit value=\"Yes\">
</td>
<td>
<input type=submit name=no_submit value=\"No\">
</td>
</tr>
</table>
</form>
</center>
[ad_scope_footer]
"
