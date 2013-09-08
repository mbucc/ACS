ad_page_contract {
    This edits properties of a chat room.

    @author Aure (aure@arsdigita.com)
    @author Philip Greenspun (philg@mit.edu)
    @author Sarah Ahmeds (ahmeds@arsdigita.com)    @param expiration_days
    @param chat_room_id room to edit
    @param active_p is this room available
    @param moderate_p is this room require approval for message posting
    @param pretty_name new name for this room
    @param group_id group this room belongs to

    @creation-date 18 November 1998
    @cvs-id edit-room.tcl,v 1.4.2.6 2000/07/21 03:59:10 ron Exp
} {
    pretty_name
    group_id:optional,naturalnum
    moderated_p
    expiration_days:integer
    active_p
    chat_room_id:naturalnum

}

ad_maybe_redirect_for_registration

set exception_count 0 
if {[empty_string_p $pretty_name]} {
    incr exception_count
    append exception_text "<li>Please give this chat room a name."
}

if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}


# it appears that group_id is never passed to this proc

if { ![exists_and_not_null group_id] } {
    set scope_sql "group_id = '',
                   scope = 'public', "
    # this wasn't set 
    set scope 'public'
} else {
    set scope_sql "group_id = :group_id,
                   scope = 'group', "
    set scope 'group'
}

set update_sql "update chat_rooms
set pretty_name=:pretty_name, 
moderated_p=:moderated_p,
$scope_sql
active_p=:active_p,
expiration_days=:expiration_days
where chat_room_id=:chat_room_id"

db_dml chat_admin_edit_room_update $update_sql 

db_release_unused_handles

#ad_returnredirect "one-room.tcl?[export_url_scope_vars chat_room_id]"
ad_returnredirect "one-room.tcl?chat_room_id=$chat_room_id"




