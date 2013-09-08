#  www/admin/ecommerce/sales-tax/clear-2.tcl
ad_page_contract {

  @author
  @creation-date
  @cvs-id clear-2.tcl,v 3.1.6.4 2000/08/18 20:23:49 stevenp Exp
} {
}



# delete all tax settings
db_dml clear_sales_taxes "delete from ec_sales_tax_by_state"
ad_audit_delete_row "" "" ec_sales_tax_by_state_audit

db_release_unused_handles

ad_returnredirect index.tcl
