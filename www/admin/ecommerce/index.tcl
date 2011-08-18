# $Id: index.tcl,v 3.0 2000/02/06 03:16:50 ron Exp $
ReturnHeaders

ns_write "[ad_admin_header "[ec_system_name] Administration"]

<h2>[ec_system_name] Administration</h2>

[ad_admin_context_bar Ecommerce]

<hr>
Documentation: <a href=\"/doc/ecommerce.html\">/doc/ecommerce.html</a>


<ul>

"

set db [ns_db gethandle]

# Problems

set unresolved_problem_count [database_to_tcl_string $db "select count(*) from ec_problems_log where resolved_date is null"]

ns_write "

<li><a href=\"problems/\">Potential Problems</a> <font size=-1>($unresolved_problem_count unresolved problem[ec_decode $unresolved_problem_count 1 "" "s"])</font>
    <p>
"

set selection [ns_db 1row $db "
select 
  sum(one_if_within_n_days(confirmed_date,1)) as n_in_last_24_hours,
  sum(one_if_within_n_days(confirmed_date,7)) as n_in_last_7_days
from ec_orders_reportable"]
set_variables_after_query

set selection [ns_db 1row $db "select count(*) as n_products, round(avg(price),2) as avg_price from ec_products_displayable"]
set_variables_after_query

ns_write "

<li><a href=\"orders/\">Orders / Shipments / Refunds</a> <font size=-1>($n_in_last_24_hours orders in last 24 hours; $n_in_last_7_days in last 7 days)</font>

<P>

<li><a href=\"products/\">Products</a> <font size=-1>($n_products products; average price: [ec_pretty_price $avg_price])</font>

<p>
<li><a href=\"customer-service/\">Customer Service</a> <font size=-1>([database_to_tcl_string $db "select count(*) from ec_customer_service_issues where close_date is null"] open issues)</font>
<p>
"

if { [ad_parameter ProductCommentsAllowP ecommerce] } {
    ns_write "<li><a href=\"customer-reviews/\">Customer Reviews</a> <font size=-1>([database_to_tcl_string $db "select count(*) from ec_product_comments where approved_p is null"] not yet approved)</font>
    <p>
    "
}

set n_not_yet_approved [database_to_tcl_string $db "select count(*) from ec_user_class_user_map where user_class_approved_p is null or user_class_approved_p='f'"]

ns_write "<li><a href=\"user-classes/\">User Classes</a> 
<font size=-1>($n_not_yet_approved not yet approved user[ec_decode $n_not_yet_approved 1 "" "s"])</font>

<p>
"


set multiple_retailers_p [ad_parameter MultipleRetailersPerProductP ecommerce]

if { $multiple_retailers_p } {
    ns_write "<li><a href=\"retailers/\">Retailers</a>\n"
} else {
    ns_write "<li><a href=\"shipping-costs/\">Shipping Costs</a>
    <li><a href=\"sales-tax/\">Sales Tax</a>\n"
}

ns_write "<li><a href=\"templates/\">Product Templates</a>
"


ns_write "<li><a href=\"mailing-lists/\">Mailing Lists</a>
<li><a href=\"email-templates/\">Email Templates</a>\n

<p>

<li><a href=\"audit-tables.tcl\">Audit [ec_system_name]</a>
</ul>

[ad_admin_footer]
"


