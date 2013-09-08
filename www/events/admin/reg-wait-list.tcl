# File:  events/admin/reg-wait-list.tcl
# Owner: bryanche@arsdigita.com
# Purpose:  Update registration status for one registration
#####

ad_page_contract {
    Updates registration status for one registration.

    @param reg_id the registration to wait-list

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id reg-wait-list.tcl,v 3.3.2.4 2000/09/22 01:37:40 kevin Exp
} {
    {reg_id:integer,notnull}
}

set reg_check [db_0or1row sel_reg_info "select p.event_id, u.email
from events_registrations r, events_prices p, users u
where r.reg_id = :reg_id
and p.price_id = r.price_id
and u.user_id = r.user_id
"]

if {!$reg_check} {
    append whole_page "
    [ad_header "Could not find registration"]
    <h2>Registration not found</h2>
    [ad_context_bar_ws [list "index.tcl" "Events Administration"] "Wait-List Registration"]
    <hr>

    Registration $reg_id was not found in the database.
    [ad_footer]"

    return
}

set event_name [events_event_name $event_id]

append whole_page "
[ad_header "Wait-List Registration"]
<h2>Wait-List Registration for $event_name</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] "Wait-List Registration"]
<hr>

<form method=post action=\"reg-wait-list-2\">
[export_form_vars reg_id]
Are you sure that you want to wait-list $email's registration for $event_name?
<p>
If you would like, you may enter a comment for why you
are wait-listing this registration:
<p>
<textarea rows=10 cols=70 name=new_comment>
</textarea>

<p>
<center>
<input type=submit value=\"Yes, Wait-List Registration\">
</center>
[ad_footer]
"


doc_return  200 text/html $whole_page
##### EOF
