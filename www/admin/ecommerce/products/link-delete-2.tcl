# $Id: link-delete-2.tcl,v 3.0.4.1 2000/04/28 15:08:52 carsten Exp $
set_the_usual_form_variables
# product_a, product_b, product_id, product_name

set db [ns_db gethandle]

ns_db dml $db "delete from ec_product_links where product_a=$product_a and product_b=$product_b"

ad_audit_delete_row $db [list $product_a $product_b] [list "product_a" "product_b"] ec_product_links_audit

ad_returnredirect "link.tcl?[export_url_vars product_id product_name]"