# Swaps two sort keys for group_type, sort_key and sort_key + 1.

set_the_usual_form_variables
# event_id, sort_key

set db [ns_db gethandle]

set next_sort_key [expr $sort_key + 1]

with_catch errmsg {
    ns_db dml $db "update events_event_fields
set sort_key = decode(sort_key, $sort_key, $next_sort_key, $next_sort_key, $sort_key)
where event_id = $event_id
and sort_key in ($sort_key, $next_sort_key)"

    ad_returnredirect "event.tcl?event_id=$event_id"
} {
    ad_return_error "Database error" "A database error occured while trying
to swap your event fields. Here's the error:
<pre>
$errmsg
</pre>
"
}