# /www/admin/ecommerce/orders/void-2.tcl
ad_page_contract {

  @author Eve Andersson (eveander@arsdigita.com)
  @creation-date Summer 1999
  @cvs-id void-2.tcl,v 3.1.6.3 2000/08/17 15:19:16 seb Exp
} {
  order_id:integer,notnull
  reason_for_void
}

ad_maybe_redirect_for_registration
set customer_service_rep [ad_get_user_id]

db_transaction {
  db_dml order_update "
  update ec_orders
  set order_state='void',
  reason_for_void=:reason_for_void,
  voided_by=:customer_service_rep,
  voided_date=sysdate
  where order_id=:order_id
  "

  db_dml items_update "
  update ec_items
  set item_state='void',
  voided_by=:customer_service_rep
  where order_id=:order_id
  "

  # Reinstate gift certificates.
  db_dml gift_certificates_reinst "declare begin ec_reinst_gift_cert_on_order(:order_id); end;"
}

ad_returnredirect "one?[export_url_vars order_id]"
