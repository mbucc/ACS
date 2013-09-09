# File:  events/admin/reg-approve.tcl
# Owner: bryanche@arsdigita.com
# Purpose:  Update registration status for one registration
#####

ad_page_contract {
    Asks about updating registration status for one registration to 'shipped'

    @param reg_id the registration we're approving

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id reg-approve.tcl,v 3.5.6.4 2000/09/22 01:37:39 kevin Exp
} {
    {reg_id:integer,notnull}
}

set reg_check [db_0or1row sel_reg "select p.event_id, u.email
from events_registrations r, events_prices p, users u
where r.reg_id = :reg_id
and p.price_id = r.price_id
and u.user_id = r.user_id
"]

if {!$reg_check} {
    append whole_page "
    [ad_header "Could not find registration"]
    <h2>Registration not found</h2>
    [ad_context_bar_ws [list "index.tcl" "Events Administration"] "Approve Registration"]
    <hr>

    Registration $reg_id was not found in the database.
    [ad_footer]"

    return
}

set event_name [events_event_name $event_id]

append whole_page "
[ad_header "Approve Registration"]
<h2>Approve Registration for $event_name</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] "Approve Registration"]
<hr>

<form method=post action=\"reg-approve-2\">
[export_form_vars reg_id]
Are you sure that you want to approve $email's registration for $event_name?
<p>
<center>
<input type=submit value=\"Yes, Approve Registration\">
</center>
[ad_footer]
"


doc_return  200 text/html $whole_page
##### EOF
