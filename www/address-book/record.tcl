# /www/address-book/record.tcl

ad_page_contract {
    Purpose:  shows a single address book record

    @param scope
    @param user_id
    @param group_id
    @param address_book_id
    @contact_info_only

    @creation-date 12/24/99
    @author teadams@arsdigita.com
    @author tarik@arsdigita.com
    @cvs-id record.tcl,v 3.2.2.12 2000/10/10 14:46:36 luke Exp
} {
    scope:optional
    user_id:optional,integer
    group_id:optional,integer
    address_book_id:integer
    contact_info_only:optional
}

ad_scope_error_check user

set user_id [ad_scope_authorize $scope none group_member user]

# Keep caller_user_id so it doesn't get clobbered by the addressbook select
set caller_user_id $user_id

set name [address_book_name]

# Get address_book info, and return a message if this address_book does not exist.
if {[db_0or1row address_book_select_all "select first_names, last_name,
email, email2, line1, line2, city, usps_abbrev, zip_code, country,
phone_home, phone_work, phone_cell, phone_other, birthday, birthmonth,
birthyear, notes
from address_book where address_book_id = :address_book_id"] == 0} {
    ad_return_error "Address book not found" "We couldn't find address book #$address_book_id" 
    return
}

set address_book_info [ad_tcl_vars_to_ns_set first_names last_name email email2 line1 line2 city usps_abbrev zip_code country phone_home phone_work phone_cell phone_other birthday birthmonth birthyear notes]

if { ![info exists contact_info_only] } {
    set contact_info_only "f"
}

set page_content "
[ad_scope_header "$first_names $last_name"]
[ad_scope_page_title "$first_names $last_name"]
[ad_scope_context_bar_ws [list "index?[export_url_scope_vars]" "Address book"] "One record"]
<hr>
[ad_scope_navbar]
"

append html "
[address_book_record_display $address_book_info $contact_info_only]
<p>
"

if { [ad_scope_administrator_p $caller_user_id] } {
    append html "\[<a href=\"http://maps.yahoo.com/py/maps.py?Pyt=Tmap&addr=[ns_urlencode "$line1 $line2"]&csz=$zip_code&Get+Map=Get+Map\">view map</a> | <a href=record-edit?[export_url_scope_vars address_book_id]>edit</a> | <a href=record-delete?[export_url_scope_vars address_book_id]>delete</a>\]
    <p>
    "
} else {
    append html "<a href=\"http://maps.yahoo.com/py/maps.py?Pyt=Tmap&addr=[ns_urlencode "$line1 $line2"]&csz=$zip_code&Get+Map=Get+Map\">view map</a>
    <p>
    "
}

append page_content "
<blockquote>
$html
</blockquote>
[ad_scope_footer]
"



doc_return  200 text/html $page_content