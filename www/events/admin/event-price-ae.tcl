#not supporting prices at this time
return

set_the_usual_form_variables
#event_id, maybe price_id

set db [ns_db gethandle]

set time_elements "
<tr>
 <td>Date available:
 <td>[_ns_dateentrywidget available_time] [_ns_timeentrywidget available_time]
<tr>
 <td>Date expires:
 <td>[_ns_dateentrywidget expire_time] [_ns_timeentrywidget expire_time]
"

if {[exists_and_not_null price_id]} {
    #we're editing
    set adding_p 0
    
    set page_title "Edit Price"
    set submit_text "Update Price"
    set selection [ns_db 1row $db "select
    product_id, price, description as product_name, 
    to_char(available_date, 'YYYY-MM-DD HH24:MI:SS') as available_timestamp,
    to_char(expire_date, 'YYYY-MM-DD HH24:MI:SS') as expire_timestamp,
    price_id
    from events_prices
    where price_id = $price_id"]

    set_variables_after_query

    set end_time [database_to_tcl_string $db "
    select to_char(end_time, 'YYYY-MM-DD HH24:MI:SS')
    from events_events
    where event_id = $event_id"]

} else {
    #we're adding
    set adding_p 1

    set page_title "Add New Price"
    set submit_text "Add Price"
#    set product_id [database_to_tcl_string $db "select ec_product_id_sequence.nextval from dual"]
    set product_name ""
    set price ""
    set price_id [database_to_tcl_string $db "select events_price_id_sequence.nextval from dual"]

    set selection [ns_db 1row $db "select
    to_char(sysdate, 'YYYY-MM-DD HH24:MI:SS') as available_timestamp,
    to_char(end_time, 'YYYY-MM-DD HH24:MI:SS') as expire_timestamp
    from events_events, dual
    where event_id = $event_id"]
    set_variables_after_query
    
    set end_time $expire_timestamp
}

set stuffed_with_a [ns_dbformvalueput $time_elements "available_time" "timestamp" $available_timestamp]
set times [ns_dbformvalueput $stuffed_with_a "expire_time" "timestamp" $expire_timestamp]

set context_bar "[ad_admin_context_bar [list "index.tcl" "Events"] "Pricing"]"

ReturnHeaders
ns_write "
[ad_partner_header]
<form method=post action=\"event-price-ae-2.tcl\">
[export_form_vars price_id product_id event_id]

<table cellpadding=5>
<tr>
 <td>Price Description:
 <td><input type=text size=30 name = \"product_name\" value=\"$product_name\">
<tr>
 <td>Price:
 <td><input type=text size=10 name = \"price\" value=\"$price\">
$times
<td>(Expiration date can be no later than $end_time)
</table>
<p>
<center>
<input type=submit value=\"$submit_text\">
</center>
</form>
[ad_partner_footer]"
