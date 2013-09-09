#role_id, and either event_id or activity_id
#maybe user_id and bio
#maybe old_user_id if deleting a user
#role, responsibilities, public_role_p,

ad_page_contract {
    Adds/updates an organizer role

    @param role_id the id of role we're editing (if editing)
    @param event_id the event to which to add the role, if adding to an event
    @param activity_id the event to which to add the role, if adding to an activity
    @param user_id optional user to place in this role
    @param bio optional bio of user_id
    @param old_user_id existing user_id in this role if we're editing and want to remove this user from the role
    @param role name of the role we're adding/editing
    @param responsibilities the responsibilities of this role
    @param public_role_p is this role public for registrants to see?

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id organizer-role-ae-2.tcl,v 3.1.6.6 2000/07/21 03:59:39 ron Exp
} {
    {role_id:integer,notnull}
    {event_id:integer,optional [db_null]}
    {activity_id:integer,optional [db_null]}
    {user_id:integer,optional [db_null]}
    {bio:html,trim,optional [db_null]}
    {old_user_id:integer,optional [db_null]}
    {role:trim,notnull}
    {responsibilities:trim,notnull}
    {public_role_p:notnull}
}

page_validation {
    set error_msg ""
    if {![exists_and_not_null event_id] && ![exists_and_not_null activity_id]} {
	append error_msg "<li>This page came in without an event or activity id"
    }

    if {![empty_string_p $error_msg]} {
	error $error_msg
    }
}

set admin_id [ad_maybe_redirect_for_registration]

set ip_address [ns_conn peeraddr]

if {[exists_and_not_null event_id]} {
    #add/edit a role for an event
    db_transaction {

    db_dml event_role_update "update events_event_organizer_roles
    set role = :role,
    responsibilities = :responsibilities,
    public_role_p = :public_role_p
    where role_id = :role_id" 

    if {[db_resultrows] == 0} {
	db_dml event_role_insert "insert into events_event_organizer_roles
	(role_id, event_id, role, responsibilities, public_role_p)
	values
	(:role_id, :event_id, :role, :responsibilities,
	:public_role_p)" 

    }

    #get the event's user group
    set group_id [db_string event_group_id "select
    group_id from events_events
    where event_id = :event_id"] 
    
    if {[exists_and_not_null user_id]} {
	#a user was specified, so set it
	db_dml evnt_org_map_update "update events_organizers_map
	set user_id = :user_id
	where role_id = :role_id" 
	if {[db_resultrows] == 0} {
	    db_dml evnt_org_map_insert "insert into events_organizers_map
	    (user_id, role_id)
	    values
	    (:user_id, :role_id)" 
	}

	#add the user's role to the event's user group if he isn't there
	set count [db_string evnt_role_count "select
	count(*) from user_group_map
	where group_id = :group_id
	and user_id = :user_id
	and role = :role" ]

	if {$count == 0} {
	    db_dml evnt_ugm_insert "insert into user_group_map
	    (group_id, user_id, role, mapping_user, mapping_ip_address) 
	    values
	    (:group_id, :user_id, :role, :admin_id, :ip_address)
	    " 
	}	    

	if {[info exists bio]} {
	    db_dml bio_update "update users
	    set bio = :bio
	    where user_id = :user_id"
	}
    } elseif {[exists_and_not_null old_user_id]} {
	#no user specified, so delete this role_id from the map
	db_dml evnt_org_delete "delete from events_organizers_map
	where role_id = :role_id
	and user_id = :old_user_id
	"

	#delete role from the user group map too
	db_dml evnt_org_map_delete "delete from user_group_map
	where group_id = :group_id
	and role = :role
	and user_id = :old_user_id
	"
    }
    
    }
} else {
    #add/edit activity
    
    db_dml activity_role_update "update events_activity_org_roles
    set role = :role,
    responsibilities = :responsibilities,
    public_role_p = :public_role_p
    where role_id = :role_id
    "

    if {[db_resultrows] == 0} {
	db_dml activity_role_insert "insert into events_activity_org_roles
	(role_id, activity_id, role, responsibilities, public_role_p)
	values
	(:role_id, :activity_id, :role, :responsibilities,
	:public_role_p)"
    }
}

if {[exists_and_not_null event_id]} {
    ad_returnredirect "event.tcl?[export_url_vars event_id]"
} else {
    ad_returnredirect "activity.tcl?[export_url_vars activity_id]"
}