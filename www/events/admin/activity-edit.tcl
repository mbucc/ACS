set user_id [ad_maybe_redirect_for_registration]

set_the_usual_form_variables

#activity_id

ReturnHeaders

set db [ns_db gethandle]

set selection [ns_db 1row $db "select short_name, description, available_p,
u.first_names || ' ' || u.last_name as creator_name,
detail_url, group_id
from events_activities, users u
where activity_id = $activity_id
and creator_id = u.user_id
"]

set_variables_after_query

ns_write "[ad_header "Edit $short_name"]

<h2>Edit $short_name</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "activities.tcl" Activities] [list "activity.tcl?[export_url_vars activity_id]" Activity] "Edit Activity"]
<hr>

<h3>Activity Description</h3>

<form method=post action=activity-edit-2.tcl>
[philg_hidden_input activity_id $activity_id]

<table>
<tr>
  <td>Activity Name
  <td><input type=text size=30 name=short_name value=\"[philg_quote_double_quotes $short_name]\">
<tr>
  <td>Creator
  <td>$creator_name
<tr>
  <td>Owning Group
  <td>[events_member_groups_widget $db $user_id $group_id]
<tr>
"

# <td>Default Price
# <td><input type=text size=10 name=default_price value=\"$default_price\">

ns_write "
<tr>
 <td>URL
 <td><input type=text size=30 name=detail_url value=\"$detail_url\">
<tr>
  <td>Description
  <td><textarea name=description rows=8 cols=70 wrap=soft>$description</textarea>
<tr>
  <td>Current or Discontinued
"
if {$available_p == "t"} {
    ns_write "<td><input type=radio name=available_p value=t CHECKED>Current
      <input type=radio name=available_p value=f>Discontinued
    "
} else {
    ns_write "<td><input type=radio name=available_p value=t>Current
      <input type=radio name=available_p value=f CHECKED>Discontinued
    "
}
ns_write "
</table>
Note: Discontinuing an activity will not cancel an activity's 
existing events. It only prevents you from adding <i>new</i> events 
to the activity.
<br>
<br>

<center>
<input type=submit value=\"Edit Activity\">
</center>
</form>

[ad_footer]
"




