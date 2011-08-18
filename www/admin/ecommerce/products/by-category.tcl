# $Id: by-category.tcl,v 3.0 2000/02/06 03:19:46 ron Exp $
# by-category.tcl
#
# by philg@mit.edu on July 18, 1999
#
# list the product categories and summary data for each (how many
# products, how many sales)

ReturnHeaders

ns_write "[ad_admin_header "Products by Category"]

<h2>Products by category</h2>

[ad_admin_context_bar [list "/admin/ecommerce/" "Ecommerce"] [list "index.tcl" "Products"] "by Category"]

<hr>

<ul>
"

set db [ns_db gethandle]
set selection [ns_db select $db "
select cats.category_id, cats.sort_key, cats.category_name, count(cat_view.product_id) as n_products, sum(cat_view.n_sold) as total_sold_in_category
from 
  ec_categories cats, 
  (select map.product_id, map.category_id, count(i.item_id) as n_sold
   from ec_category_product_map map, ec_items_reportable i
   where map.product_id = i.product_id(+)
   group by map.product_id, map.category_id) cat_view
where cats.category_id = cat_view.category_id(+)
group by cats.category_id, cats.sort_key, cats.category_name
order by cats.sort_key"]

set items ""

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append items "<li><a href=\"list.tcl?[export_url_vars category_id]\">$category_name</a> 
&nbsp;
<font size=-1>($n_products products; $total_sold_in_category sales)</font>\n"
}

if ![empty_string_p $items] {
    ns_write $items
} else {
    ns_write "apparently products aren't being put into categories"
}

ns_write "

</ul>


[ad_admin_footer]
"




