# /www/address-book/records.tcl

ad_page_contract {
    
    Purpose:  shows the list of address book records    

    @param scope
    @param user_id
    @param group_id
    @param contact_info_only
    @param order_by

    @cvs-id records.tcl,v 3.2.2.12 2000/10/10 14:46:36 luke Exp
    @creation-date mid-1998
    @author teadams@arsdigita.com
    @author tarik@arsdigita.com

} {
    scope:optional
    user_id:optional,integer
    group_id:optional,integer
    contact_info_only:optional
    order_by:optional
}


ad_scope_error_check user

set user_id [ad_scope_authorize $scope none group_member user]

set scope_administrator_p [ad_scope_administrator_p $user_id]

set name [address_book_name]

if { ![info exists contact_info_only] } {
    set contact_info_only "f"
}
if { ![info exists order_by] } {
    set order_by "last_name, first_names"
}

set page_content "

[ad_scope_header "All Records for $name"]
[ad_scope_page_title "All Records for $name"]
[ad_scope_context_bar_ws [list "index?[export_url_scope_vars]" "Address Book"] "All Records"]
<hr>
[ad_scope_navbar]
"

set n_records [db_string address_book_records_count "
select count(*) from address_book where [ad_scope_sql]"]

if { $n_records == 0 } {
    append html "
    There are currently no addresses.
    <p>
    <a href=record-add?[export_url_scope_vars]>Add a Record</a>
    "
    append page_content "
    <blockquote>
    $html
    </blockquote>
    [ad_scope_footer]
    <blockquote>
    "
    return
} elseif {$n_records == 1} {
    append page_content "$n_records record<br> "
} else {
    append page_content "$n_records records<br> "
} 

if { $contact_info_only == "t" } {
    append address_string "
    <a href=\"records?contact_info_only=f&[export_url_scope_vars]\">Display All Info</a><p>"
} else {
    append address_string "
    <a href=\"records?contact_info_only=t&[export_url_scope_vars]\">Display Only Contact Info</a><p>"
}

db_foreach address_book_records_loop "select first_names, last_name,
email, email2, line1, line2, city, usps_abbrev, zip_code, country,
phone_home, phone_work, phone_cell, phone_other, birthday, birthmonth,
birthyear, notes
from address_book where [ad_scope_sql] order by :order_by" {

    set set_data [ad_tcl_vars_to_ns_set first_names last_name email email2 line1 line2 city usps_abbrev zip_code country phone_home phone_work phone_cell phone_other birthday birthmonth birthyear notes]
    append address_string "
    [address_book_record_display $set_data $contact_info_only]"
    if { $contact_info_only == "f" && $scope_administrator_p } {
	append address_string "
	<br>\[<a href=record-edit?[export_url_scope_vars address_book_id]>edit</a> | <a href=record-delete?[export_url_scope_vars address_book_id]>delete</a>\]"
    }
    append address_string "<p>"
}

append page_content "
$address_string
"

if { $scope_administrator_p } {
    append page_content "
    <p>
    <a href=record-add?[export_url_scope_vars]>Add a Record</a>
    "
}

append page_content "
</blockquote>
[ad_scope_footer]
"



doc_return  200 text/html $page_content