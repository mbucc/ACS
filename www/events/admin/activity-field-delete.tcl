set_the_usual_form_variables
# activity_id, column_name, pretty_name

set db [ns_db gethandle]

set selection [ns_db 1row $db "select 
activity_id, short_name as activity_name
from events_activities
where activity_id = $activity_id
"]

set_variables_after_query

ns_return 200 text/html "[ad_header "Delete Field From $activity_name"]

<h2>Delete Column $column_name</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "activities.tcl" Activities] [list "activity.tcl?[export_url_vars activity_id]" Activity] "Custom Field"]
<hr>

<form action=\"activity-field-delete-2.tcl\" method=POST>
[export_form_vars activity_id column_name]

Do you really want to remove this field from the activity, $activity_name?
<p>
You may not be able to undo this action.
<center>
<input type=submit value=\"Yes, Remove This Field\">
</center>

[ad_footer]
"