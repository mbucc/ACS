ad_page_contract {
    Displays information about an event organizer

    @param role_id the organizer's role
    @param user_id the organizer

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id organizer.tcl,v 3.1.6.4 2000/09/22 01:37:34 kevin Exp
} {
    {role_id:integer,notnull}
    {user_id:integer,notnull}
}


set org_check [db_0or1row sel_organizer_info "select
eo.event_id, eo.role,
u.bio, u.first_names || ' ' || u.last_name as organizer_name
from events_organizers eo, users u
where eo.role_id = :role_id
and eo.public_role_p = 't'
and eo.user_id = :user_id
and u.user_id = :user_id"]

if {!$org_check} {
    ad_return_complaint "Invalid Organizer Request This page
    came in with an invalid organizer request."
    return
}

set bio [ad_decode $bio "" "$organizer_name has not provided any information about himself to display" $bio]

append whole_page "
[ad_header "$organizer_name: $role"]
<h3>$organizer_name: $role for [events_pretty_event $event_id]</h3>
[ad_context_bar_ws [list "index.tcl" "Events"] [list "event-info.tcl?[export_url_vars event_id]" "Event"] "$role"]
<hr>
About $organizer_name:
<p>
$bio
[ad_footer]
"


doc_return  200 text/html $whole_page
