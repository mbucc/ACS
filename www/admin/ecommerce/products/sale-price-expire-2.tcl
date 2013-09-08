#  www/admin/ecommerce/products/sale-price-expire-2.tcl
ad_page_contract {
  Expire a sale.

  @author Eve Andersson (eveander@arsdigita.com)
  @creation-date Summer 1999
  @cvs-id sale-price-expire-2.tcl,v 3.1.6.3 2000/08/18 20:23:47 stevenp Exp
} {
  sale_price_id:integer,notnull
  product_id:integer,notnull
}

# we need them to be logged in
ad_maybe_redirect_for_registration
set user_id [ad_get_user_id]

set peeraddr [ns_conn peeraddr]

db_dml expire_sale_update "
update ec_sale_prices
set sale_ends=sysdate,
    last_modified=sysdate,
    last_modifying_user=:user_id,
    modified_ip_address=:peeraddr
where sale_price_id=:sale_price_id
"
db_release_unused_handles

ad_returnredirect "sale-prices.tcl?[export_url_vars product_id]"
