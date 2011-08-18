# $Id: comments.tcl,v 3.0 2000/02/06 03:18:56 ron Exp $
set_the_usual_form_variables
# order_id

set db [ns_db gethandle]

ReturnHeaders
ns_write "[ad_admin_header "Comments"]

<h2>Comments</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Orders"] [list "one.tcl?order_id=$order_id" "One Order"] "Comments"]

<hr>

<form method=post action=comments-edit.tcl>
[export_form_vars order_id]

Please add or edit comments below:

<br>

<blockquote>
<textarea name=cs_comments rows=15 cols=50 wrap>[database_to_tcl_string $db "select cs_comments from ec_orders where order_id=$order_id"]</textarea>
</blockquote>

<p>
<center>
<input type=submit value=\"Submit\">
</center>

</form>

[ad_admin_footer]
"