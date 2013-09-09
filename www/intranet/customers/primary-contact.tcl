# /www/intranet/customers/primary-contact.tcl

ad_page_contract {
    Lets you select a primary contact from the group's address book

    @param group_id customer's group id

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000
    @cvs-id primary-contact.tcl,v 3.8.2.9 2000/09/22 01:38:28 kevin Exp
} {
    group_id:integer,notnull
}

ad_maybe_redirect_for_registration


set customer_name [db_string customer_name {
    select g.group_name
      from im_customers c, user_groups g
     where c.group_id = :group_id
       and c.group_id=g.group_id}]
    
set contact_info ""
set sql "select address_book_id, first_names, last_name, email, email2,
         line1, line2, city, country, birthmonth, birthyear, 
         usps_abbrev, zip_code,
         phone_home, phone_work, phone_cell, phone_other, notes
         from address_book
         where group_id = :group_id
         order by lower(last_name)"

db_foreach address_book_info $sql  {
    set address_book_info [ad_tcl_vars_to_ns_set address_book_id first_names \
	    last_name email email2 line1 line2 city country birthmonth birthyear \
	    usps_abbrev zip_code phone_home phone_work phone_cell phone_other notes]
    append contact_info "<p><li>[address_book_display_one_row]</a><br>
      (<a href=primary-contact-2?[export_url_vars group_id address_book_id]>
      make primary contact</a>)\n"    
} 

db_release_unused_handles

if { [empty_string_p $contact_info] } {
    ad_return_error "No contacts listed" "Before you can select a primary contact, you must <a href=/address-book/record-add?scope=group&[export_url_vars group_id return_url]>add at least 1 person to the address book</a>"
    return
}

set return_url "[im_url_stub]/customers/view?[export_url_vars group_id]"

set page_title "Select primary contact for $customer_name"
set context_bar [ad_context_bar_ws [list ./ "Customers"] [list view?[export_url_vars group_id] "One customer"] "Select contact"]

set page_body "
<ul>
$contact_info
</ul>
"

doc_return  200 text/html [im_return_template]
