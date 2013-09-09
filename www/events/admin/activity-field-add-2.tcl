# File:  events/admin/activity-field-add-2.tcl
# Owner: bryanche@arsdigita.com
# Purpose:  Carry out field addition specified in a-f-a-1.tcl, 
#    catch errors in field addition, print out verification message.
#####

ad_page_contract {
    Carry out field addition specified in a-f-a-1.tcl, 
    catch errors in field addition, print out verification message.

    @param activity_id the activity to which we're adding a field
    @param column_name column name of the new field
    @param pretty_name pretty name of the new field
    @param column_type the type of the colum
    @param column_actual_type the actual sql type of the column
    @param column_extra extra sql properties for the field
    @param after field after which to insert this field

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id activity-field-add-2.tcl,v 3.7.2.7 2000/09/22 01:37:35 kevin Exp
} {
    {activity_id:integer}
    {column_name:trim,notnull}
    {pretty_name:trim,notnull}
    {column_type}
    {column_actual_type:trim,notnull}
    {column_extra:trim [db_null]}
    {after [db_null]}
}

#make sure that column_name is valid
if {[regexp {([^A-z])+} $column_name match]} {
    if {[regexp {([^0-9])+} $match match2]} {
	#the column name is invalid
	ad_return_complaint 1 "<li>You have entered an invalid
	<i>Column Actual Name</i>"
	return
    }
}

db_transaction {
    #lock this table so that we can get the sort key w/o race conditions
    db_dml lock_events_activity_fields "lock table events_activity_fields in exclusive mode"

    #make sure that this column doesn't already exist
    if { [exists_and_not_null after] } {
	set sort_key [expr $after + 1]
	set update_sql "update events_activity_fields 
	set sort_key = :sort_key
	where activity_id = :activity_id
	and sort_key > :after" 
    } else {
	#we don't use a sequence because
	#we support swapping fields
	set sort_key [db_string sel_max_sort_key "select
	nvl(max(sort_key),0) + 1
	from events_activity_fields
	where activity_id = :activity_id"]
	set update_sql ""
    }

    set col_count [db_string check_column "select
    count(*)
    from events_activity_fields
    where activity_id = :activity_id
    and column_name = :column_name"]

    if {$col_count > 0} {
	ad_return_warning "Custom Field Already Exists" "You cannot add this 
	custom field because it already exists."
	return
    }

    set insert_sql "insert into events_activity_fields 
    (activity_id, column_name, pretty_name, column_type, 
    column_actual_type, column_extra, sort_key)
    values
    (:activity_id, :column_name, :pretty_name, :column_type, 
    :column_actual_type, :column_extra, :sort_key)"

    if { ![empty_string_p $update_sql] } {
	db_dml update_field $update_sql
	set insert_sql ""
    }
    db_dml insert_field $insert_sql
} on_error {
    # an error
 ad_return_error "Database Error" "Error while trying to customize the activity.
	
Tried the following SQL:
	    
<blockquote> \n <pre>
$update_sql
$insert_sql    
</pre> \n </blockquote>	

and got back the following:
	
<blockquote> \n <pre>
$errmsg
</pre> \n </blockquote>"
    return
}

### database stuff went OK; we return a confirmation message

doc_return  200 text/html "[ad_header "Field Added"]

<h2>Field Added</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "activities.tcl" Activities] [list "activity.tcl?[export_url_vars activity_id]" Activity] "Custom Field"]
<hr>

The following action has been taken:

<ul>
<li>a row has been added to the SQL table events_activity_fields
reflecting that 

<ul>
<li>this field has the pretty name (for user interface) of \"$pretty_name\"

</ul></ul>

[ad_footer]
"

##### EOF
