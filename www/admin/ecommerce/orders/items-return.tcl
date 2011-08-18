# $Id: items-return.tcl,v 3.0.4.1 2000/04/28 15:08:45 carsten Exp $
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

# in case they reload this page after completing the refund process:
if { [database_to_tcl_string $db "select count(*) from ec_items_refundable where order_id=$order_id"] == 0 } {
    ad_return_complaint 1 "<li>This order doesn't contain any refundable items; perhaps you are using an old form.  <a href=\"one.tcl?[export_url_vars order_id]\">Return to the order.</a>"
    return
}

ReturnHeaders
ns_write "[ad_admin_header "Mark Items Returned"]

<h2>Mark Items Returned</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Orders"] [list "one.tcl?order_id=$order_id" "One Order"] "Mark Items Returned"]

<hr>
"
# generate the new refund_id here (we don't want them reusing this form)
set refund_id [database_to_tcl_string $db "select refund_id_sequence.nextval from dual"]


ns_write "<form method=post action=items-return-2.tcl>
[export_form_vars order_id refund_id]

<blockquote>
Date received back:
[ad_dateentrywidget received_back_date] [ec_timeentrywidget received_back_date "[ns_localsqltimestamp]"]

<p>

Please check off the items that were received back:
<blockquote>
[ec_items_for_fulfillment_or_return $db $order_id "f"]
</blockquote>

Reason for return (if known):
<blockquote>
<textarea name=reason_for_return rows=5 cols=50 wrap>
</textarea>
</blockquote>

</blockquote>

<p>
<center>
<input type=submit value=\"Continue\">
</center>

</form>

[ad_admin_footer]
"