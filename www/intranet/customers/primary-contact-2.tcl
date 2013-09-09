# /www/intranet/customers/primary-contact-2.tcl

ad_page_contract {
    Writes customer's primary contact to the db

    @param group_id customer's group id
    @param address_book_id id of the address_book record to set as the primary contact

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000
    @cvs-id primary-contact-2.tcl,v 3.4.2.5 2000/08/16 21:24:42 mbryzek Exp

} {
    group_id:integer,notnull
    address_book_id:integer,notnull
    
}

ad_maybe_redirect_for_registration

db_dml customers_set_primary_contact \
	"update im_customers 
            set primary_contact_id=:address_book_id
          where group_id=:group_id" 

db_release_unused_handles

ad_returnredirect view?[export_url_vars group_id]