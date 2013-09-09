#  www/admin/ecommerce/orders/fulfillment-items-needed.tcl
ad_page_contract {
  Items needed for fulfillment.

  @author Eve Andersson (eveander@arsdigita.com)
  @creation-date Summer 1999
  @cvs-id fulfillment-items-needed.tcl,v 3.3.2.3 2000/08/16 18:49:05 seb Exp
} {
}

doc_body_append "[ad_admin_header "Items Needed"]

<h2>Items Needed</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index" "Orders"] [list "fulfillment" "Fulfillment"] "Items Needed"]

<hr>
The following items are needed in order to fulfill all outstanding orders:
<blockquote>
<table>
<tr bgcolor=\"ececec\"><td><b>Quantity</b></td><td><b>Product</b></td></tr>
"



db_foreach items_needed_select "select p.product_id, p.product_name, i.color_choice, i.size_choice, i.style_choice, count(*) as quantity
from ec_products p, ec_items_shippable i
where p.product_id=i.product_id
group by p.product_id, p.product_name, i.color_choice, i.size_choice, i.style_choice
order by quantity desc" {
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

    doc_body_append "<tr><td align=right>$quantity</td><td><a href=\"/admin/ecommerce/products/one?[export_url_vars product_id]\">$product_name</a>[ec_decode $options "" "" "; $options"]</td></tr>\n"
}

doc_body_append "</table>
</blockquote>
[ad_admin_footer]
"
