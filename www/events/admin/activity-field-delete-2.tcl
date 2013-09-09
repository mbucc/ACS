# File:  events/admin/activity-field-delete-2.tcl
# Owner: bryanche@arsdigita.com
# Purpose: To verify that a field has been dropped from a given activity,
#    or show the error that prevented this action.
#####

ad_page_contract {
    Verifies that a field has been dropped from a given activity,
    or shows the error that prevented this action.

    @param activity_id the field's activity
    @param column_name the name of the field's table column

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id activity-field-delete-2.tcl,v 3.5.6.5 2000/09/22 01:37:35 kevin Exp
} {
    {activity_id:integer}
    {column_name}
}

db_transaction {
    db_dml delete_field "delete from events_activity_fields
 where activity_id = :activity_id
   and column_name = :column_name "
} on_error {
    ad_return_error "Deletion Failed" "We were unable to drop the column $column_name from the activity due to a database error:
<pre>
$errmsg
</pre>
"
    return
}


doc_return  200 text/html "[ad_header "Field Removed"]
<h2>Field Removed</h2> 
[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "activities.tcl" Activities] [list "activity.tcl?[export_url_vars activity_id]" Activity] "Custom Field"]
<hr>

The following action has been taken:
<ul>
 <li>The $column_name field was dropped from this activity.
 <li>a row was removed from the table events_activity_fields.
</ul>

[ad_footer]
"

##### EOF
