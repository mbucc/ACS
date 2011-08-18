set_the_usual_form_variables
#reg_id

set db [ns_db gethandle]

set selection [ns_db 0or1row $db "select p.event_id, u.email
from events_registrations r, events_prices p, users u
where r.reg_id = $reg_id
and p.price_id = r.price_id
and u.user_id = r.user_id
"]

ReturnHeaders

if {[empty_string_p $selection]} {
    ns_write "
    [ad_header "Could not find registration"]
    <h2>Registration not found</h2>
    <a href=\"index.tcl\">[ad_system_name] events</a> 
    <hr>
    Registration $reg_id was not found in the database.

    [ad_footer]"

    return
}

set_variables_after_query

set event_name [events_event_name $db $event_id]

ns_write "
[ad_header "Approve Registration"]
<h2>Approve Registration for $event_name</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] "Approve Registration"]
<hr>
<form method=post action=\"reg-approve-2.tcl\">
[export_form_vars reg_id]
Are you sure that you want to approve $email's registration for $event_name?
<p>
<center>
<input type=submit value=\"Yes, Approve Registration\">
</center>
[ad_footer]
"