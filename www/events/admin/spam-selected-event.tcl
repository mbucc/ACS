set_the_usual_form_variables
#event_id

set admin_id [ad_maybe_redirect_for_registration]

ReturnHeaders

ns_write "[ad_header "Spam Event"]"

set db_pools [ns_db gethandle subquery 2]
set db [lindex $db_pools 0]
set db_sub [lindex $db_pools 1]


ns_write "

<h2>Spam Event</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] "Spam Event"]

<hr>

[events_pretty_event $db $event_id]<br>
Spam:
<ul>
"
set sql_post_select "from users, events_reg_shipped r, events_prices p
where p.event_id = $event_id
and users.user_id = r.user_id
and p.price_id = r.price_id
"

ns_write "
<li><a href=\"spam/action-choose.tcl?[export_url_vars sql_post_select]\">
Confirmed Registratants</a>
"

set sql_post_select "from users, events_registrations r, events_prices p
where p.event_id = $event_id
and users.user_id = r.user_id
and p.price_id = r.price_id
and r.reg_state = 'pending'
"

ns_write "
<li><a href=\"spam/action-choose.tcl?[export_url_vars sql_post_select]\">
Pending Registratants</a>
"

set sql_post_select "from users, events_registrations r, events_prices p
where p.event_id = $event_id
and users.user_id = r.user_id
and p.price_id = r.price_id
and r.reg_state = 'waiting'
"

ns_write "
<li><a href=\"spam/action-choose.tcl?[export_url_vars sql_post_select]\">
Wait-listed Registratants</a>
"

set sql_post_select "from users, events_registrations r, events_prices p
where p.event_id = $event_id
and users.user_id = r.user_id
and p.price_id = r.price_id
"

ns_write "
<li><a href=\"spam/action-choose.tcl?[export_url_vars sql_post_select]\">
All Registrants</a>
"


ns_write "</ul>[ad_footer]"