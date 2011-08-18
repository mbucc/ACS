# $Id: records.tcl,v 3.0 2000/02/06 02:44:22 ron Exp $
# File:     /address-book/records.tcl
# Date:     mid-1998
# Contact:  teadams@arsdigita.com, tarik@arsdigita.com
# Purpose:  shows the list of address book records
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)


set_the_usual_form_variables 0
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)
# maybe contact_info_only, maybe order_by
ad_scope_error_check user
set db [ns_db gethandle]
set user_id [ad_scope_authorize $db $scope none group_member user]

set scope_administrator_p [ad_scope_administrator_p $db $user_id]

set name [address_book_name $db]

if { ![info exists contact_info_only] } {
    set contact_info_only "f"
}
if { ![info exists order_by] } {
    set order_by "last_name, first_names"
}

ReturnHeaders

ns_write "

[ad_scope_header "All Records for $name" $db]
[ad_scope_page_title "All Records for $name" $db]
[ad_scope_context_bar_ws [list "index.tcl?[export_url_scope_vars]" "Address Book"] "All Records"]
<hr>
[ad_scope_navbar]
"



set n_records [database_to_tcl_string $db "
select count(*) from address_book where [ad_scope_sql]"]

if { $n_records == 0 } {
    append html "
    There are currently no addresses.
    <p>
    <a href=record-add.tcl?[export_url_scope_vars]>Add a Record</a>
    "
    ns_write "
    <blockquote>
    $html
    </blockquote>
    [ad_scope_footer]
    "
    return
} elseif {$n_records == 1} {
    append html "$n_records record<br> "
} else {
    append html "$n_records records<br> "
} 

if { $contact_info_only == "t" } {
    append address_string "
    <a href=\"records.tcl?contact_info_only=f&[export_url_scope_vars]\">Display All Info</a><p>"
} else {
    append address_string "
    <a href=\"records.tcl?contact_info_only=t&[export_url_scope_vars]\">Display Only Contact Info</a><p>"
}


set selection [ns_db select $db "
select * from address_book where [ad_scope_sql] order by $order_by"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append address_string "
    [address_book_record_display $selection $contact_info_only]"
    if { $contact_info_only == "f" && $scope_administrator_p } {
	append address_string "
	<br>\[<a href=record-edit.tcl?[export_url_scope_vars address_book_id]>edit</a> | <a href=record-delete.tcl?[export_url_scope_vars address_book_id]>delete</a>\]"
    }
    append address_string "<p>"
}


append html "
$address_string
"

if { $scope_administrator_p } {
    append html "
    <p>
    <a href=record-add.tcl?[export_url_scope_vars]>Add a Record</a>
    "
}

ns_write "
<blockquote>
$html
</blockquote>
[ad_scope_footer]
"
