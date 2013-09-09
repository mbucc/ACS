#  www/admin/ecommerce/products/toggle-active-p.tcl
ad_page_contract {

  @author Eve Andersson (eveander@arsdigita.com)
  @creation-date Summer 1999
  @cvs-id toggle-active-p.tcl,v 3.1.6.2 2000/07/22 07:57:46 ron Exp
} {
  product_id:integer,notnull
}

# we need them to be logged in
ad_maybe_redirect_for_registration
set user_id [ad_get_user_id]

set peeraddr [ns_conn peeraddr]

db_dml toggle_active_p_update "
update ec_products 
set active_p = logical_negation(active_p),
    last_modified = sysdate, 
    last_modifying_user = :user_id,
    modified_ip_address = :peeraddr
where product_id = :product_id
"

ad_returnredirect "one.tcl?[export_url_vars product_id]"
