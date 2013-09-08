# File:  events/admin/activity-field-delete.tcl
# Owner: bryanche@arsdigita.com
# Purpose: Allows admins to confirm the deletion of a field 
#     associated with the selected activity
#####

ad_page_contract {
    Allows admins to confirm the deletion of a field 
    associated with the selected activity

    @param activity_id the field's activity
    @param column_name the name of the field's table column

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id activity-field-delete.tcl,v 3.6.6.4 2000/09/22 01:37:35 kevin Exp
} {
    {activity_id:integer}
    {column_name}
}

db_1row activity_info "
  select activity_id, short_name as activity_name
    from events_activities
   where activity_id = :activity_id "


doc_return  200 text/html "[ad_header "Delete Field From $activity_name"]

<h2>Delete Field $column_name</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "activities.tcl" Activities] [list "activity.tcl?[export_url_vars activity_id]" Activity] "Custom Field"]
<hr>

<form action=\"activity-field-delete-2\" method=POST>
[export_form_vars activity_id column_name]

Do you really want to remove this field from the activity, $activity_name?
<p>
You may not be able to undo this action.
<center> <input type=submit value=\"Yes, Remove This Field\"> </center>

[ad_footer]
"

##### EOF
