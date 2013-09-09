# File: event-field-swap.tcl
# Owner: bryanche@arsdigita.com
#####

ad_page_contract {
    Swaps two sort keys for group_type, sort_key and the next sort_key

    @param event_id the event whose fields we are swapping
    @param sort_key the key of the field whose order we are swapping with the next field

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id event-field-swap.tcl,v 3.4.6.4 2000/07/21 03:59:37 ron Exp
} {
    {event_id:integer}
    {sort_key:integer}
}

db_transaction {
    #lock this table so that we can get the sort key w/o race conditions
    db_dml lock_events_event_fields "lock table events_event_fields in exclusive mode"

    #set next_sort_key [expr $sort_key + 1]
    #get the next sort key from the db
    set key_list [db_list next_key "
    select sort_key as next_sort_key
    from events_event_fields
    where event_id = :event_id
    and sort_key > :sort_key
    order by sort_key
    " ]
    set next_sort_key [lindex $key_list 0]

    #this shouldn't happen, but to make the code more robust...
    if {[empty_string_p $next_sort_key]} {
	set next_sort_key $sort_key 
    }

    set sort_key_list [list ":sort_key" ":next_sort_key"]
    db_dml swap_fields "update events_event_fields
    set sort_key = decode(sort_key,:sort_key,:next_sort_key,
    :next_sort_key,:sort_key)
    where event_id = :event_id
    and sort_key in ([join $sort_key_list ", "])"
    
} on_error {
    ad_return_warning "Database error" "A database error occured while trying
    to swap your event fields. Here's the error:
    <pre> $errmsg </pre> "
    return
}

db_release_unused_handles
ad_returnredirect "event.tcl?event_id=$event_id"

##### File OveR
