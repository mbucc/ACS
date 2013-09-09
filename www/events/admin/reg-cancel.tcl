# File:  events/admin/reg-cancel.tcl
# Owner: bryanche@arsdigita.com
# Purpose:  Cancel one registration
#####

ad_page_contract {
    prompts to cancel a registration

    @param reg_id the registration to cancel

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id reg-cancel.tcl,v 3.6.6.4 2000/09/22 01:37:39 kevin Exp
} {
    {reg_id:integer,notnull}
}

set reg_check [db_0or1row sel_reg "
 select p.event_id, u.email
  from events_registrations r, events_prices p, users u
  where r.reg_id = :reg_id
  and p.price_id = r.price_id
  and u.user_id = r.user_id
"]

if {!$reg_check} {
    append whole_page "
    [ad_header "Could not find registration"]
    <h2>Registration not found</h2>
    [ad_context_bar_ws [list "index.tcl" "Events Administration"] "Cancel Registration"]
    <hr>

    Registration $reg_id was not found in the database.
    [ad_footer]"

    return
}

set event_name [events_event_name $event_id]

append whole_page "
[ad_header "Cancel Registration"]
<h2>Cancel Registration for $event_name</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] "Cancel Registration"]
<hr>

<form method=post action=\"reg-cancel-2\">
[export_form_vars reg_id]
Are you sure that you want to cancel $email's registration for $event_name?
<p>
If you'd like, you may enter an explanation for why you are canceling/denying
this registration:
<p>
<textarea wrap=soft cols=80 rows=5 name=cancel_reason>
</textarea>
<p>
<center>
<input type=submit value=\"Yes, Cancel Registration\">
</center>
[ad_footer]
"


doc_return  200 text/html $whole_page
##### EOF
