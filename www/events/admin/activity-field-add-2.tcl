set_the_usual_form_variables

# activity_id, column_name, pretty_name, column_type, column_actual_type
# column_extra, after (optional)

set db [ns_db gethandle]

if { [exists_and_not_null after] } {
    set sort_key [expr $after + 1]
    set update_sql "update events_activity_fields 
    set sort_key = sort_key + 1
    where activity_id = $activity_id
    and sort_key > $after"
} else {
    set sort_key 1
    set update_sql ""
}


set insert_sql "insert into events_activity_fields (activity_id, column_name, pretty_name, column_type, column_actual_type, column_extra, sort_key)
values
( $activity_id, '$QQcolumn_name', '$QQpretty_name','$QQcolumn_type', '$QQcolumn_actual_type', [ns_dbquotevalue $column_extra text], $sort_key)"

with_transaction $db {
    if { ![empty_string_p $update_sql] } {
	ns_db dml $db $update_sql
    }
    ns_db dml $db $insert_sql
} {
    # an error
    ad_return_error "Database Error" "Error while trying to customize the activity.
	
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
</blockquote>"
    return
}

# database stuff went OK
ns_return 200 text/html "[ad_header "Field Added"]

<h2>Field Added</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "activities.tcl" Activities] [list "activity.tcl?[export_url_vars activity_id]" Activity] "Custom Field"]
<hr>

The following action has been taken:

<ul>

<li>a row has been added to the SQL table events_activity_fields
reflecting that 

<ul>

<li>this field has the pretty name (for user interface) of \"$pretty_name\"

</ul>
</ul>

[ad_footer]
"
