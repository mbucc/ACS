ad_page_contract {
    Deletes an organizer role.

    @param role_id the role to delete
    @param event_id the event to which the role belongs (if it's for an event)
    @param activity_id the activity to which the role belongs (if it's for an activity)

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id organizer-role-delete-2.tcl,v 3.1.6.3 2000/07/21 03:59:39 ron Exp
} {
    {role_id:integer,notnull}
    {event_id:integer,optional}
    {activity_id:integer,optional}
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
    
    db_transaction {

    #first delete the role from the map
    db_dml evnt_org_map_del "delete from events_organizers_map
    where role_id = :role_id"

    #then, delete the role
    db_dml evnt_role_del "delete from events_event_organizer_roles
    where role_id = :role_id"

    }

    set return_url "event.tcl?[export_url_vars event_id]"
} else {
    #delete role from an activity

    db_dml act_role_del "delete from events_activity_org_roles
    where role_id = :role_id"

    set return_url "activity.tcl?[export_url_vars activity_id]"
}

db_release_unused_handles
ad_returnredirect $return_url
    