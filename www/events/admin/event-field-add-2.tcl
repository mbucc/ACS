#     File:  admin/event-field-add-2.tcl
#    Owner:  bryanche@arsdigita.com
#  Purpose:  This processes the form from event-field-add.tcl and
#            gives the user specific feedback about what was done.
#####

ad_page_contract {
    This processes the form from event-field-add.tcl and
    gives the user specific feedback about what was done.
    
    @param event_id the event to which we're adding a field
    @param column_name column name of the new field
    @param pretty_name pretty name of the new field
    @param column_type the type of the colum
    @param column_actual_type the actual sql type of the column
    @param column_extra extra sql properties for the field
    @param after field after which to insert this field

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id event-field-add-2.tcl,v 3.6.2.7 2000/09/22 01:37:36 kevin Exp
} {
    {event_id:integer}
    {column_name:trim,notnull}
    {pretty_name:trim,notnull}
    {column_type}
    {column_actual_type:trim,notnull}
    {column_extra:trim [db_null]}
    {after [db_null]}
}

set table_name [events_helper_table_name $event_id]

db_transaction {
    #lock this table so that we can get the sort key w/o race conditions
    db_dml lock_events_event_fields "lock table events_event_fields in exclusive mode"

    if { [exists_and_not_null after] } {
	set sort_key [expr $after + 1]
	set update_sql "update events_event_fields 
    	set sort_key = :sort_key
    	where event_id = :event_id
    	and sort_key > :after"
    } else {
	#we don't use a sequence because
	#we support swapping fields
	set sort_key [db_string sel_max_sort_key "select
	nvl(max(sort_key),0) + 1
	from events_event_fields
	where event_id = :event_id"]
	set update_sql ""
    }

    #make sure that this column doesn't already exist
    set col_count [db_string sel_col_count "select
    count(*)
    from events_event_fields
    where event_id = :event_id
    and column_name = :column_name
    "]

    if {$col_count > 0} {
	ad_return_warning "Custom Field Already Exists" "You cannot add this 
	custom field because it already exists."
	return
    }

    set alter_sql "alter table $table_name add ($column_name $column_actual_type $column_extra)"

    set insert_sql "insert into events_event_fields 
    (event_id, column_name, pretty_name, column_type, 
    column_actual_type, column_extra, sort_key)
    values
    (:event_id, :column_name, :pretty_name, :column_type, 
    :column_actual_type, :column_extra, :sort_key)"

    db_dml alter_table $alter_sql
    if { ![empty_string_p $update_sql] } {
	db_dml update_field $update_sql
    }
    db_dml insert_field $insert_sql
} on_error {
    # if there's an error
    ad_return_warning "Database Error" "Error while trying to customize the event.
    
    Tried the following SQL:
    
    <blockquote>
    <pre>
    $alter_sql
    $update_sql
    $insert_sql    
    </pre>
    </blockquote>	
    
    and got back the following:
    
    <blockquote>
    <pre>
    $errmsg
    </pre>
    </blockquote>
    "
    return
}

db_release_unused_handles

# else database stuff went OK
doc_return  200 text/html "[ad_header "Field Added"]

<h2>Field Added</h2>

[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "activities.tcl" Activities] [list "activity.tcl?[export_url_vars activity_id]" Activity] [list "event.tcl?[export_url_vars event_id]" Event] "Custom Field"]
<hr>

The following action has been taken: 
<ul>
 <li>a column called \"$column_name\" has been added to the
table $table_name in the database.  The sql was

<p>
<code>
 <blockquote>
$alter_sql
 </blockquote>
</code>
<p>

 <li>a row has been added to the SQL table events_event_fields
reflecting that 	
	<ul>
	 <li>this field has the pretty name (for user interface) of \"$pretty_name\"
	</ul>
</ul>

[ad_footer]
"

##### File Over
