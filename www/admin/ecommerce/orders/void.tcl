# $Id: void.tcl,v 3.0.4.1 2000/04/28 15:08:46 carsten Exp $
set_the_usual_form_variables
# order_id

# we need them to be logged in
set customer_service_rep [ad_verify_and_get_user_id]

if {$customer_service_rep == 0} {
    set return_url "[ns_conn url]?[export_entire_form_as_url_vars]"
    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

set db [ns_db gethandle]

ReturnHeaders
ns_write "[ad_admin_header "Void Order"]

<h2>Void Order</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Orders"] [list "one.tcl?order_id=$order_id" "One Order"] "Void"]

<hr>
"

set n_shipped_items [database_to_tcl_string $db "select count(*) from ec_items where order_id=$order_id and item_state in ('shipped', 'arrived', 'received_back')"]

if { $n_shipped_items > 0 } {
    ns_write "<font color=red>Warning:</font> our records show that at least one item in this
    order has already shipped, which means that the customer has already been charged
    (for shipped items only).  Voiding an order will not cause
    the customer's credit card to be refunded (you can only do that by marking
    individual items \"received back\").
    <p>
    Voiding is usually done if the customer cancels their order before it ships. 
    <p>
    "
}

ns_write "Note: this will cause all individual items in this order
to be marked 'void'.
<p>"

ns_write "
<form method=post action=void-2.tcl>
[export_form_vars order_id]

Please explain why you are voiding this order:

<br>

<blockquote>
<textarea name=reason_for_void rows=5 cols=50 wrap>
</textarea>
</blockquote>

<p>
<center>
<input type=submit value=\"Void It!\">
</center>

</form>

[ad_admin_footer]
"