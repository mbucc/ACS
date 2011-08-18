# $Id: primary-contact.tcl,v 3.1.4.1 2000/03/17 08:22:54 mbryzek Exp $
# File: /www/intranet/customers/primary-contact.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Lets you select a primary contact from the group's address book
#

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set_form_variables
# group_id

set db [ns_db gethandle]

set customer_name [database_to_tcl_string $db \
	"select g.group_name
           from im_customers c, user_groups g
          where c.group_id = $group_id
            and c.group_id=g.group_id"]

set contact_info ""
set selection [ns_db select $db \
	"select * 
           from address_book 
          where group_id=$group_id
       order by lower(last_name)"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append contact_info "<p><li>[address_book_record_display $selection "f"]</a><br>(<a href=primary-contact-2.tcl?[export_url_vars group_id address_book_id]>make primary contact</a>) \n"
    
} 

ns_db releasehandle $db

set return_url "[im_url_stub]/customers.tcl?[export_url_vars group_id]"

if { [empty_string_p $contact_info] } {
    ad_return_error "No contacts listed" "Before you can select a primary contact, you must <a href=/address-book/record-add.tcl?scope=group&[export_url_vars group_id return_url]>add at least 1 person to the address book</a>"
    return
}

set page_title "Select primary contact for $customer_name"
set context_bar [ad_context_bar [list "/" Home] [list "../" "Intranet"] [list index.tcl "Customers"] [list view.tcl?[export_url_vars group_id] "One customer"] "Select contact"]

set page_body "
<ul>
$contact_info
</ul>
"


ns_return 200 text/html [ad_partner_return_template]
