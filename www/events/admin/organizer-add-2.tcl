# File:  events/admin/organizer-add-2.tcl
# Owner: bryanche@arsdigita.com
# Purpose: Add an organizer to an event.
#####

ad_page_contract {
    Adds an organizer to an event.

    @param user_id_from_search user_id from /user-search.tcl
    @param first_name_from_search from /user-search.tcl
    @param last_name from /user-search.tcl
    @param email from /user-search.tcl
    @param event_id the event to which we're adding an organizer
    @param role_id optional role_id to pass through

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id organizer-add-2.tcl,v 3.6.6.5 2000/09/22 01:37:38 kevin Exp
} {
    {user_id_from_search:integer,notnull}
    {first_names_from_search}
    {last_name_from_search}
    {email_from_search}
    {event_id:integer,notnull}
    {role_id:integer,optional}
}

# check if this guy is already a organizer
#set selection [ns_db 0or1row $db "select 1 from
#events_organizers_map
#where user_id = $user_id_from_search
#and event_id = $event_id
#"]
#if {![empty_string_p $selection]} {
#    set org_name [db_string unused "select 
#    first_names || ' ' || last_name
#    from users
#    where user_id=$user_id_from_search"]
#    ad_return_error "Organizer Already Exists" "You have already 
#    given $org_name an organizing role for this event.  You may
#    <ul>
#     <li><a href=\"organizer-edit?user_id=$user_id_from_search&event_id=$event_id\">view/edit
#     this organizer's responsibilities</a>
#     <li><a href=\"index\">return to administration</a>
#    </ul>"
#    return
#}

#set bio [db_string unused "select bio from users 
#where user_id = $user_id_from_search"]

db_1row org_info "select a.short_name as event_name,
a.activity_id,
u.bio
from events_activities a, events_events e, users u
where e.event_id = :event_id
and a.activity_id = e.activity_id
and u.user_id = :user_id_from_search
"



doc_return  200 text/html "[ad_header "Add a New Organizer"]
<h2>Add a New Organizer</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "activities.tcl" Activities] [list "activity.tcl?[export_url_vars activity_id]" Activity] [list "event.tcl?[export_url_vars event_id]" "Event"] "Add Organizer"]
<hr>

<form method=post action=organizer-role-ae>
[export_form_vars event_id role_id user_id_from_search]
You have selected $first_names_from_search
$last_name_from_search ($email_from_search) to be an organizer for the
$event_name event.
<p>
You may update this user's biography if you wish:
<p>
<textarea name=bio rows=10 cols=70 wrap=soft>$bio</textarea>
<p>
<center>
<input type=submit value=\"Select this user\">
</center>
</form>
[ad_footer]
"
#####
