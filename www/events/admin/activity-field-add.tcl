# File:  events/admin/activity-field-add.tcl
# Owner: bryanche@arsdigita.com
# Purpose: allows admins to add a custom field to the registrations
#    forms for all events associated with the chosen activity.
#####

ad_page_contract {
    Purpose: allows admins to add a custom field to the registrations
    forms for all events associated with the chosen activity.

    @param activity_id the activity to which we are adding a field
    @param after field after which this new field will appear

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id activity-field-add.tcl,v 3.6.6.4 2000/09/22 01:37:35 kevin Exp
} {
    {activity_id:integer}
    {after:optional}
}

db_1row activity_info "
  select activity_id, short_name as activity_name
    from events_activities
   where activity_id = $activity_id "



doc_return  200 text/html "[ad_header "Add a field to $activity_name"]

<h2>Add a field</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "activities.tcl" Activities] [list "activity.tcl?[export_url_vars activity_id]" Activity] "Custom Field"]
<hr>

<p>
Add a field to the activity, $activity_name.
<p>
<form action=\"activity-field-add-2\" method=POST>
[export_form_vars activity_id after]

Column Actual Name:  <input name=column_name type=text size=30>
<br>
<i>no spaces or special characters except underscore</i>

<p>
Column Pretty Name:  <input name=pretty_name type=text size=30>
<p>

Column Type:  [ad_user_group_column_type_widget]
<p>

Column Actual Type:  <input name=column_actual_type type=text size=30>
(used to feed Oracle, e.g., <code>char(1)</code> instead of boolean)

<p>

If you're a database wizard, you might want to add some 
extra SQL, such as \"not null\"<br>
Extra SQL: <input type=text size=30 name=column_extra>

<p>
(note that you can only truly add not null columns when the table is
empty, i.e., before anyone has entered the contest)
<p>

<input type=submit value=\"Add this new column\">

</form>

[ad_footer]
"

##### EOF
