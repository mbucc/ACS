# $Id: fulfillment-items-needed.tcl,v 3.1 2000/03/07 04:10:02 eveander Exp $
ReturnHeaders

ns_write "[ad_admin_header "Items Needed"]

<h2>Items Needed</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Orders"] [list "fulfillment.tcl" "Fulfillment"] "Items Needed"]

<hr>
The following items are needed in order to fulfill all outstanding orders:
<blockquote>
<table>
<tr bgcolor=\"ececec\"><td><b>Quantity</b></td><td><b>Product</b></td></tr>
"

set db [ns_db gethandle]

set selection [ns_db select $db "select p.product_id, p.product_name, i.color_choice, i.size_choice, i.style_choice, count(*) as quantity
from ec_products p, ec_items_shippable i
where p.product_id=i.product_id
group by p.product_id, p.product_name, i.color_choice, i.size_choice, i.style_choice
order by quantity desc"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query

    set option_list [list]
    if { ![empty_string_p $color_choice] } {
	lappend option_list "Color: $color_choice"
    }
    if { ![empty_string_p $size_choice] } {
	lappend option_list "Size: $size_choice"
    }
    if { ![empty_string_p $style_choice] } {
	lappend option_list "Style: $style_choice"
    }
    set options [join $option_list ", "]


    ns_write "<tr><td align=right>$quantity</td><td><a href=\"/admin/ecommerce/products/one.tcl?[export_url_vars product_id]\">$product_name</a>[ec_decode $options "" "" "; $options"]</td></tr>\n"
}

ns_write "</table>
</blockquote>
[ad_admin_footer]
"
