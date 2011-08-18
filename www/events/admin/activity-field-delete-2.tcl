set_the_usual_form_variables

# activity_id, column_name

set db [ns_db gethandle]

with_transaction $db {
    ns_db dml $db "delete from events_activity_fields
where activity_id = $activity_id
and column_name = '$QQcolumn_name'"
} {
    ad_return_error "Deletion Failed" "We were unable to drop the column $column_name from the activity due to a database error:
<pre>
$errmsg
</pre>
"
    return
}

ns_return 200 text/html "[ad_header "Field Removed"]
[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "activities.tcl" Activities] [list "activity.tcl?[export_url_vars activity_id]" Activity] "Custom Field"]
<h2>Field Removed</h2>

from the activity.

<hr>

The following action has been taken:

<ul>
<li>a row was removed from the table events_activity_fields.
</ul>

[ad_footer]
"