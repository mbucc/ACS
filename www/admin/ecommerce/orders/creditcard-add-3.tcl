#  www/admin/ecommerce/orders/creditcard-add-3.tcl
ad_page_contract {

  @author Eve Andersson (eveander@arsdigita.com)
  @creation-date Summer 1999
  @cvs-id creditcard-add-3.tcl,v 3.1.6.3 2000/08/16 18:49:04 seb Exp
} {
  order_id:insert,notnull
  creditcard_number:notnull
  creditcard_type:notnull
  creditcard_expire_1
  creditcard_expire_2
  billing_zip_code
}

db_transaction {

  set user_id [db_string user_id_select "select user_id from ec_orders where order_id=:order_id"]

  set creditcard_id [db_string creditcard_id_select "select ec_creditcard_id_sequence.nextval from dual"]

  set creditcard_last_four [string range $creditcard_number [expr [string length $creditcard_number] -4] [expr [string length $creditcard_number] -1]]
  set creditcard_expire "$creditcard_expire_1/$creditcard_expire_2"

  db_dml creditcard_insert_select "insert into ec_creditcards
  (creditcard_id, user_id, creditcard_number, creditcard_last_four, creditcard_type, creditcard_expire, billing_zip_code)
  values
  (:creditcard_id, :user_id, :creditcard_number, :creditcard_last_four, :creditcard_type, :creditcard_expire, :billing_zip_code)
  "

  db_dml ec_orders_update "update ec_orders set creditcard_id=:creditcard_id where order_id=:order_id"
}

ad_returnredirect "one?[export_url_vars order_id]"
