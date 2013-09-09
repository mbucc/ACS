#  www/admin/ecommerce/products/recommendation-delete-2.tcl
ad_page_contract {
  Actually deletes the row.

  @author philg@mit.edu
  @creation-date July 18, 1999
  @cvs-id recommendation-delete-2.tcl,v 3.1.6.2 2000/07/22 07:57:42 ron Exp
} {
  recommendation_id:integer,notnull
}

db_dml recommendation_delete "delete from ec_product_recommendations where recommendation_id=:recommendation_id"

ad_audit_delete_row [list $recommendation_id] [list recommendation_id] ec_product_recommend_audit

ad_returnredirect "recommendations.tcl"
