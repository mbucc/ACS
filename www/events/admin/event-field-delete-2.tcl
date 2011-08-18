set_the_usual_form_variables

# event_id, column_name

set db [ns_db gethandle]

set table_name [events_helper_table_name $event_id]

with_transaction $db {
    ns_db dml $db "delete from events_event_fields
where event_id = $event_id
and column_name = '$QQcolumn_name'"
    ns_db dml $db "alter table $table_name drop column $column_name"
} {
    ad_return_error "Deletion Failed" "We were unable to drop the column $column_name from the event due to a database error:
<pre>
$errmsg
</pre>
"
    return
}

ns_return 200 text/html "[ad_header "Field Removed"]
[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "activities.tcl" Activities] [list "activity.tcl?[export_url_vars activity_id]" Activity] [list "event.tcl?[export_url_vars event_id]" Event] "Custom Field"]
<h2>Field Removed</h2>

from the event.

<hr>

The following action has been taken:

<ul>

<li>the column \"$column_name\" was removed from the table
$table_name.
<li>a row was removed from the table events_event_fields.
</ul>

[ad_footer]
"