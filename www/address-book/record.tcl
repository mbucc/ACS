# $Id: record.tcl,v 3.0 2000/02/06 02:44:22 ron Exp $
# File:     /address-book/record.tcl
# Date:     12/24/99
# Contact:  teadams@arsdigita.com, tarik@arsdigita.com
# Purpose:  shows a single address book record
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

set_the_usual_form_variables 0
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)
# address_book_id and possibly contact_info_only

ad_scope_error_check user
set db [ns_db gethandle]
set user_id [ad_scope_authorize $db $scope none group_member user]

set name [address_book_name $db]

set selection [ns_db 1row $db "select * from
address_book where address_book_id = $address_book_id"]

set_variables_after_query

if { ![info exists contact_info_only] } {
    set contact_info_only "f"
}

ReturnHeaders

ns_write "
[ad_scope_header "$first_names $last_name" $db]
[ad_scope_page_title "$first_names $last_name" $db]
[ad_scope_context_bar_ws [list "index.tcl?[export_url_scope_vars]" "Address book"] "One record"]
<hr>
[ad_scope_navbar]
"

append html "
[address_book_record_display $selection $contact_info_only]
<p>
"

if { [ad_scope_administrator_p $db $user_id] } {
    append html "\[<a href=\"http://maps.yahoo.com/py/maps.py?Pyt=Tmap&addr=[ns_urlencode "$line1 $line2"]&csz=$zip_code&Get+Map=Get+Map\">view map</a> | <a href=record-edit.tcl?[export_url_scope_vars address_book_id]>edit</a> | <a href=record-delete.tcl?[export_url_scope_vars address_book_id]>delete</a>\]
    <p>
    "
} else {
    append html "<a href=\"http://maps.yahoo.com/py/maps.py?Pyt=Tmap&addr=[ns_urlencode "$line1 $line2"]&csz=$zip_code&Get+Map=Get+Map\">view map</a>
    <p>
    "
}

ns_write "
<blockquote>
$html
</blockquote>
[ad_scope_footer]
"
