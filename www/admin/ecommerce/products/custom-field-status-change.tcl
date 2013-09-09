#  www/admin/ecommerce/products/custom-field-status-change.tcl
ad_page_contract {

  @author Eve Andersson (eveander@arsdigita.com)
  @creation-date Summer 1999
  @cvs-id custom-field-status-change.tcl,v 3.1.6.2 2000/07/22 07:57:38 ron Exp
} {
  field_identifier:sql_identifier
  active_p
}

# we need them to be logged in
ad_maybe_redirect_for_registration
set user_id [ad_get_user_id]

set peeraddr [ns_conn peeraddr]

db_dml status_update "
update ec_custom_product_fields
set active_p = :active_p,
    last_modified = sysdate,
    last_modifying_user = :user_id,
    modified_ip_address = :peeraddr
where field_identifier = :field_identifier
"

ad_returnredirect custom-fields.tcl
