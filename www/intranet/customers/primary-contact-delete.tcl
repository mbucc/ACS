# /www/intranet/customers/primary-contact-delete.tcl

ad_page_contract {
    Removes customer's primary contact

    @param group_id customer's group id
    @param return_url where to go once we're done

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000
    @cvs-id primary-contact-delete.tcl,v 3.3.2.5 2000/08/16 21:24:42 mbryzek Exp

} {
    group_id:integer
    return_url
}

ad_maybe_redirect_for_registration

db_dml customers_delete_primary_contact \
	"update im_customers
            set primary_contact_id=null
          where group_id=:group_id" 

db_release_unused_handles

ad_returnredirect $return_url
