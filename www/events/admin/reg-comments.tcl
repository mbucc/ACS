set_the_usual_form_variables

#reg_id

ReturnHeaders

set db [ns_db gethandle]

set selection [ns_db 1row $db "select r.comments, 
p.event_id, r.reg_date,
u.first_names, u.last_name
from events_registrations r, events_events e, users u, events_prices p
where p.event_id = e.event_id
and u.user_id = r.user_id
and r.reg_id = $reg_id
and p.price_id = r.price_id
"]

set_variables_after_query

ns_write "[ad_header "Add/Edit Comments Regarding Registration #$reg_id"]

<h2>Add/Edit Comments Regarding Registration #$reg_id</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] "Order History"]

<hr>

<h3>Comments</h3>

on this order from $first_names $last_name on $reg_date for 
[events_event_name $db $event_id]

<form method=post action=reg-comments-2.tcl>
[philg_hidden_input reg_id $reg_id]

<textarea name=comments rows=4 cols=70 wrap=soft>$comments</textarea>

<br>
<br>

<center>
<input type=submit value=\"Submit Comments\">
</center>
</form>
[ad_footer]
"




