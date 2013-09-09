# /www/intranet/customers/primary-contact-users-2.tcl

ad_page_contract {
    Allows you to have a primary contact that references the users
    table. We don't use this yet, but it will indeed be good once all
    customers are in the users table

    @param group_id customer's group id
    @param user_id_from_search user we're setting as the primary contact

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000
    @cvs-id primary-contact-users-2.tcl,v 3.4.2.5 2000/08/16 21:24:43 mbryzek Exp

} {
    group_id:integer
    user_id_from_search
}


ad_maybe_redirect_for_registration


db_dml customers_set_primary_contact \
	"update im_customers 
            set primary_contact_id=:user_id_from_search
          where group_id=:group_id" 
db_release_unused_handles


ad_returnredirect view?[export_url_vars group_id]










