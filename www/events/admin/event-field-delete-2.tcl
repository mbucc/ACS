# File: events/admin/event-field-delete-2.tcl
# Owner: bryanche@arsdigita.com
# Purpose: This page tries to carry out the deletion specified in 
#          event-field-delete.tcl and provides feedback afterwards.
#####

ad_page_contract {
    This page tries to carry out the deletion specified in 
    event-field-delete.tcl and provides feedback afterwards.

    @param event_id the event whose field we are deleting
    @param column_name the column of the field we are deleting

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id event-field-delete-2.tcl,v 3.4.6.4 2000/09/22 01:37:36 kevin Exp
} {
    {event_id:integer,notnull}
    {column_name}
}



set table_name [events_helper_table_name $event_id]

db_transaction {
    db_dml delete_field "delete from events_event_fields
	where  event_id = :event_id
	  and  column_name = :column_name"
    db_dml drop_col "alter table $table_name drop column $column_name"
} on_error {
    ad_return_error "Deletion Failed" "We were unable to drop the column $column_name from the event due to a database error:
 <pre> 
$errmsg 
 </pre>
"
    return
}

doc_return  200 text/html "
    [ad_header "Field Removed"]
<h2>Field Removed</h2> 

[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "activities.tcl" Activities] [list "activity.tcl?[export_url_vars activity_id]" Activity] [list "event.tcl?[export_url_vars event_id]" Event] "Custom Field"]
<hr>

The following action has been taken: 

<ul>
 <li>the column \"$column_name\" was removed from the table
$table_name.
 <li>a row was removed from the table events_event_fields.
</ul>

[ad_footer]
"

##### File Over
