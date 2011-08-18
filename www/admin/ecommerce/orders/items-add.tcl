# $Id: items-add.tcl,v 3.0 2000/02/06 03:19:18 ron Exp $
set_the_usual_form_variables
# order_id

ReturnHeaders
ns_write "[ad_admin_header "Add Items"]

<h2>Add Items</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Orders"] [list "one.tcl?order_id=$order_id" "One Order"] "Add Items"]

<hr>
<blockquote>
Search for a product to add:

<ul>


<form method=post action=items-add-2.tcl>
[export_form_vars order_id]
<li>By Name: <input type=text name=product_name size=20>
<input type=submit value=\"Search\">
</form>

<p>

<form method=post action=items-add-2.tcl>
[export_form_vars order_id]
<li>By ID: <input type=text name=product_id size=3>
<input type=submit value=\"Search\">
</form>

</ul>

</blockquote>
[ad_admin_footer]
"




