#either event_id or activity_id, and maybe role_id if editing
#maybe user_id_from_search, maybe bio

ad_page_contract {
    Adds or edits an organizer role for either an activity or an event.

    @param event_id the event to which to add the role, if adding to an event
    @param activity_id the event to which to add the role, if adding to an activity
    @param role_id the id of role we're editing (if editing)
    @param user_id_from_search optional user to place in this role
    @param bio optional bio of user_id_from_search

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id organizer-role-ae.tcl,v 3.3.6.6 2000/09/22 01:37:39 kevin Exp
} {
    {event_id:integer,optional}
    {activity_id:integer,optional}
    {role_id:integer,optional}
    {user_id_from_search:optional}
    {bio:html,trim,optional}
}


set return_url "/events/admin/organizer-role-ae.tcl?[export_url_vars event_id activity_id role_id]"

if {[exists_and_not_null role_id]} {
    #we're editing
    set editing_p 1

    if {[exists_and_not_null event_id]} {
	#we're editing an event
	set event_p 1
	set page_title "Edit Event Organizer Role"
	set submit_button "Update Role"

	#check to see if we have a user selected to be the organizer
	if {[exists_and_not_null user_id_from_search]} {
	    if {$user_id_from_search == -1} {
		set user_sql_sel "'' as email, '' as organizer_name"
		set user_sql_clause ""
		set users_table ""
	    } else {
		set user_sql_sel "u.email, u.first_names || ' ' || u.last_name as organizer_name"
		set user_sql_clause "and u.user_id = :user_id_from_search"
		set users_table ", users u"
	    }

	} else {
	    set user_sql_sel "u.email, u.first_names || ' ' || u.last_name as organizer_name"
	    set user_sql_clause "and eo.user_id = u.user_id(+)"
	    set users_table ", users u"
	}

	set role_sel [db_0or1row evnt_selrole "select
	eo.role, eo.responsibilities, eo.public_role_p, eo.user_id,
	e.activity_id,
	$user_sql_sel
	from events_organizers eo, events_events e $users_table
	where eo.role_id = :role_id
	and eo.event_id = :event_id
	and e.event_id = :event_id
	$user_sql_clause"]

	if {!$role_sel} {
	    ad_return_warning "Invalid role id" "This page came in
	    with an invalid role id"
	    return
	}

	set context_bar "[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "activities.tcl" Activities] [list "activity.tcl?[export_url_vars activity_id]" Activity] [list "event.tcl?[export_url_vars event_id]" "Event"] "Organizer Role"]"

    } elseif {[exists_and_not_null activity_id]} {
	#we're editing an activity
	set event_p 0
	set page_title "Edit Default Activity Organizer Role"
	set submit_button "Update Default Role"
	set context_bar "[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "activities.tcl" Activities] [list "activity.tcl?[export_url_vars activity_id]" Activity] "Organizer Role"]"

	set role_sel [db_0or1row sel_activity_role "select
	role, responsibilities, public_role_p
	from events_activity_org_roles
	where role_id = :role_id
	and activity_id = :activity_id
	"]

	if {!$role_sel} {
	    ad_return_warning "Invalid role id" "This page came in
	    with an invalid role id"
	    return
	}
    } else {
	#error--not enough variables
	ad_return_warning "No activity/event ID" "This page came in
	without an activity or an event id"
	return
    }
} else {
    #we're adding
    set editing_p 0

    if {[exists_and_not_null event_id]} {
	#we're adding an event role
	set event_p 1
	set page_title "Add Event Organizer Role"
	set submit_button "Add Role"

	set role_id [db_string role_seq "select
	events_event_org_roles_seq.nextval from dual"]
	set role ""
	set responsibilities ""
	set public_role_p "f"

	if {[exists_and_not_null user_id_from_search] && ($user_id_from_search) != -1} {
	    db_1row sel_organizer_info "select
	    user_id, email,
	    first_names || ' ' || last_name as organizer_name
	    from users
	    where user_id = :user_id_from_search"
	} else {
	    set organizer_name ""
	    set email ""
	    set user_id ""
	}

	set activity_id [db_string sel_activity_id "select
	activity_id from events_events 
	where event_id = :event_id"]

	set context_bar "[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "activities.tcl" Activities] [list "activity.tcl?[export_url_vars activity_id]" Activity] [list "event.tcl?[export_url_vars event_id]" "Event"] "Organizer Role"]"
    } elseif {[exists_and_not_null activity_id]} {
	#we're adding an activity role
	set event_p 0
	set page_title "Add Default Activity Organizer Role"
	set submit_button "Add Default Role"
	set context_bar "[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "activities.tcl" Activities] [list "activity.tcl?[export_url_vars activity_id]" Activity]  "Organizer Role"]"

	set role_id [db_string role_id_nextval "select
	events_activity_org_roles_seq.nextval from dual"]
	set role ""
	set responsibilities ""
	set public_role_p "f"
    } else {
	#error--not enough variables
		ad_return_warning "No activity/event ID" "This page came in
	without an activity or an event id"
	return
    }
}

if {$event_p} {
    #add/edit an EVENT organizer role

    if {[exists_and_not_null user_id_from_search]} {
	if {$user_id_from_search != -1} {
	    set user_id $user_id_from_search
	} else {
	    set old_user_id $user_id
	    set user_id ""
	}
    }

    #this value is set if we're deleting a user from this role
    if {![exists_and_not_null old_user_id]} {
	set old_user_id ""
    }

    append whole_page "
    [ad_header $page_title]
    <h3>$page_title</h3>
    $context_bar

    <hr>
    <form method=post action=\"organizer-role-ae-2\">
    [export_form_vars role_id event_id user_id old_user_id]
    <table>
    <tr>
     <th>Role
     <td><input type=text size=20 name=role value=\"$role\">
    <tr>
     <th>Responsibilities
     <td><textarea name=responsibilities rows=10 cols=70>$responsibilities</textarea>
    <tr>
     <th>Public Role?
     <td><select name=public_role_p>
         <option value=f [ad_decode $public_role_p "f" "selected" "t" "" "selected"]>
         No
         <option value=t [ad_decode $public_role_p "t" "selected" ""]>Yes
         </select>
         (Is this role visible from the event registration page?)
    <tr>
     <th>User in this role
     <td>[ad_decode $email "" "<i>None</i>" "$organizer_name ($email)"]
         <a href=\"organizer-add?[export_url_vars [ad_decode $editing_p 1 role_id ""] event_id return_url]\">
         Pick a different user for this role</a>" 
    if {![empty_string_p $email]} {
	append whole_page "
	|
	<a href=\"organizer-role-ae?[export_url_vars [ad_decode $editing_p 1 role_id ""] event_id ]&user_id_from_search=-1\">Do not specify a user</a>"
    }
	
    #see if we have a bio either from editing or from the db
    if {[exists_and_not_null user_id]} {
	if {![exists_and_not_null bio]} {
	    set bio [db_string user_bio "select
	    bio from users where user_id = :user_id"]
	}
	append whole_page "
	<tr>
	 <td>
	 <td><b>$organizer_name's biography:</b> <br>
	<textarea name=bio rows=6 cols=70 wrap=soft>$bio</textarea>
	"
    }

    append whole_page "
    </table>
    <p>
    <center>
    <input type=submit value=\"$submit_button\">
    </center>
    </form>
    "
    if {$editing_p} {
	append whole_page "
	<hr width=75%>
	<h3>Delete Organizer Role</h3>
	You may also delete this organizer role:
	<form method=post action=organizer-role-delete>
	[export_form_vars role_id event_id activity_id]
        
	<center><input type=submit value=\"Delete Role\"></center>
	</form>"
    }

    append whole_page "
    [ad_footer]
    "
} else {
    #add/edit an ACTIVITY organizer role
    append whole_page "
    [ad_header $page_title]
    <h3>$page_title</h3>
    $context_bar
    <hr>
    <form method=post action=\"organizer-role-ae-2\">
    [export_form_vars role_id activity_id]
    <table>
    <tr>
     <th>Role
     <td><input type=text size=20 name=role value=\"$role\">
    <tr>
     <th>Responsibilities
     <td><textarea name=responsibilities rows=10 cols=70>$responsibilities</textarea>
    <tr>
     <th>Public Role?
     <td><select name=public_role_p>
         <option value=f [ad_decode $public_role_p "f" "selected" "t" "" "selected"]>
         No
         <option value=t [ad_decode $public_role_p "t" "selected" ""]>Yes
         </select>
         (Is this role visible from the event registration page?)
    </table>
    <p>
    <center>
    <input type=submit value=\"$submit_button\">
    </center>
    </form>
    "
    if {$editing_p} {
	append whole_page "
	<hr width=75%>
	<h3>Delete Organizer Role</h3>
	You may also delete this organizer role:
	<form method=post action=organizer-role-delete>
	[export_form_vars role_id event_id activity_id]
        
	<center><input type=submit value=\"Delete Role\"></center>
	</form>"
    }

    append whole_page "
    [ad_footer]
    "
}

doc_return  200 text/html $whole_page