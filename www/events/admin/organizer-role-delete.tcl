ad_page_contract {
    Confirms the user wants to delete and organizer role.

    @param role_id the role to delete
    @param event_id the event to which the role belongs (if it's for an event)
    @param activity_id the activity to which the role belongs (if it's for an activity)

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id organizer-role-delete.tcl,v 3.2.6.5 2000/09/22 01:37:39 kevin Exp
} {
    {role_id:naturalnum,notnull}
    {event_id:naturalnum,optional}
    {activity_id:naturalnum,optional}
}

#check for double click
if {[db_string org_dbl_clk "select count(*) from events_event_organizer_roles where role_id=:role_id"] != 1} {
    ad_return_warning "Invalid Role ID" "This page came in with an invalid role id.  Perhaps you double-clicked?"
}



page_validation {
    set err_msg ""
    
     if {![exists_and_not_null event_id] && ![exists_and_not_null activity_id]} {
	append err_msg "<li>This page came in without an event id or an 
	activity id"
    }

    if {![empty_string_p $err_msg]} {
	error $err_msg
    }
}


if {[exists_and_not_null event_id]} {
    #delete role from an event
    db_1row event_role "select
    role, event_id
    from events_event_organizer_roles
    where role_id=:role_id
    "

    set delete_what [events_pretty_event $event_id]
    set context_bar "[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "activities.tcl" Activities] [list "activity.tcl?[export_url_vars activity_id]" Activity] [list "event.tcl?[export_url_vars event_id]" "Event"] "Organizer Role"]"
} else {
    #delete role from an activity
    db_1row activity_role "select
    role, short_name
    from events_activity_org_roles eor, events_activities a
    where eor.role_id=:role_id
    and a.activity_id = eor.activity_id
    "
    
    set delete_what $short_name
    set context_bar "[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "activities.tcl" Activities] [list "activity.tcl?[export_url_vars activity_id]" Activity] "Organizer Role"]"
}



doc_return  200 text/html "
[ad_header "Delete Organizer Role"]
<h3>Delete Organizer Role from $delete_what</h3>
$context_bar
<hr>
<form method=post action=\"organizer-role-delete-2\">
[export_form_vars role_id event_id activity_id]
Are you sure that you want to delete the role, $role,
from $delete_what?
<p>
<center>
<input type=submit value=\"Yes, Delete Role\">
</center>
</form>
[ad_footer]
"