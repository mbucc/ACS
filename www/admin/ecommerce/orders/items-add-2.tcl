# $Id: items-add-2.tcl,v 3.1 2000/03/07 04:40:15 eveander Exp $
set_the_usual_form_variables
# order_id and
# product_id or product_name

ReturnHeaders
ns_write "[ad_admin_header "Add Items, Cont."]

<h2>Add Items, Cont.</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Orders"] [list "one.tcl?order_id=$order_id" "One Order"] "Add Items, Cont."]

<hr>
"

if { [info exists product_id] } {
    set additional_query_part "product_id=[ns_dbquotevalue $product_id number]"
} else {
    set additional_query_part "upper(product_name) like '%[string toupper $QQproduct_name]%'"
}

set db_pools [ns_db gethandle [philg_server_default_pool] 2]
set db [lindex $db_pools 0]
set db_sub [lindex $db_pools 1]

set selection [ns_db select $db "select product_id, product_name from ec_products where $additional_query_part"]

set product_counter 0
while {[ns_db getrow $db $selection]} {
    if { $product_counter == 0 } {
	ns_write "Here are the product(s) that match your search.
	<p>
	Note: the customer's credit card is not going to be reauthorized when you add this item to the order (their card was already found to be valid when they placed the intial order).  They will, as usual, be automatically billed for this item when it ships.  If the customer's credit limit is in question, just make a test authorization offline.
	<ul>
	"
    }
    incr product_counter
    set_variables_after_query
#    ns_write "<li><a href=\"items-add-3.tcl?[export_url_vars order_id product_id]\">$product_name</a>\n"
    ns_write "<li><a href=\"/admin/ecommerce/products/one.tcl?[export_url_vars product_id]\">$product_name</a>
    <br>
    [ec_add_to_cart_link $db_sub $product_id "Add to Order" "Add to Order" "items-add-3.tcl" $order_id]
    <p>
    "
}

if { $product_counter == 0 } {
    ns_write "No matching products were found.\n"
} else {
    ns_write "</ul>"
}

ns_write "
[ad_admin_footer]
"