set db [ns_db gethandle]

set_the_usual_form_variables

#event_id, user_id, biography, role, responsibilities

# check if this guy is already a organizer
set selection [ns_db 0or1row $db "select 1 from
events_organizers_map
where user_id = $user_id
and event_id = $event_id
"]
if {![empty_string_p $selection]} {
    set org_name [database_to_tcl_string $db "select 
    first_names || ' ' || last_name
    from users
    where user_id=$user_id_from_search"]
    ad_return_error "Organizer Already Exists" "You have already 
    given $org_name an organizing role for this event.  You may
    <ul>
     <li><a href=\"organizer-edit.tcl?user_id=$user_id_from_search&event_id=$event_id\">view/edit
     this organizer's responsibilities</a>
     <li><a href=\"index.tcl\">return to administration</a>
    </ul>"
    return
}

#error check
set exception_text ""
set exception_count 0

if {![exists_and_not_null role]} {
    incr exception_count
    append exception_text "<li>You must enter a role"
}

if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}


ns_db dml $db "begin transaction"
ns_db dml $db "insert into events_organizers_map
(event_id, user_id, role, responsibilities)
values ($event_id, $user_id, '$QQrole', '$QQresponsibilities')" 
ns_db dml $db "update users 
set bio='$QQbio'
where user_id = $user_id"

ns_db dml $db "end transaction"

ad_returnredirect "event.tcl?[export_url_vars event_id]"
