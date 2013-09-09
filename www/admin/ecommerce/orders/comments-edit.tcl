# /www/admin/ecommerce/orders/comments-edit.tcl
ad_page_contract {

  Update the comments field of ec_orders.

  @author Eve Andersson (eveander@arsdigita.com)
  @creation-date Summer 1999
  @cvs-id comments-edit.tcl,v 3.1.6.3 2000/08/16 16:28:51 seb Exp
} {
  order_id:integer,notnull
  cs_comments
}

db_dml cs_comments_update "update ec_orders set cs_comments=:cs_comments where order_id=:order_id"

ad_returnredirect "one?[export_url_vars order_id]"
