#  www/admin/ecommerce/products/recommendation-text-edit-2.tcl
ad_page_contract {
  Actually updates the row.

  @author philg@mit.edu
  @creation-date July 18, 1999
  @cvs-id recommendation-text-edit-2.tcl,v 3.1.6.2 2000/07/22 07:57:42 ron Exp
} {
  recommendation_id:integer,notnull
  recommendation_text:html
}

# we need them to be logged in
ad_maybe_redirect_for_registration
set user_id [ad_get_user_id]

set peeraddr [ns_conn peeraddr]

db_dml recommendation_text_update "
update ec_product_recommendations 
set recommendation_text = :recommendation_text,
    last_modified=sysdate,
    last_modifying_user=:user_id,
    modified_ip_address=:peeraddr
where recommendation_id=:recommendation_id
"

ad_returnredirect "recommendation.tcl?[export_url_vars recommendation_id]"
