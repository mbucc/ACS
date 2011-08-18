set user_id [ad_maybe_redirect_for_registration]

set db [ns_db gethandle]

ReturnHeaders

set new_activity_id [database_to_tcl_string $db "select events_activity_id_sequence.nextval from dual"]

ns_write "[ad_header "Add a new activity"]

<h2>Add a New Activity</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "activities.tcl" Activities] "Add Activity"]

<hr>

<h3>Activity Description</h3>

<form method=post action=activity-add-2.tcl>
[philg_hidden_input activity_id $new_activity_id]
[philg_hidden_input creator_id $user_id]

<table>
<tr>
  <td>Activity Name
  <td><input type=text size=30 name=short_name>
<tr>
  <td>Owning Group
  <td>[events_member_groups_widget $db $user_id]
<tr>
  <td>Details URL:
  <td><input type=text size=30 name=detail_url>
<tr>
  <td>(link to page with more details)
"

#<tr>
# <td>Default Price: 
# <td><input type=text size=10 name=default_price value=0>

ns_write "
<tr>
  <td>Description
  <td><textarea name=description rows=8 cols=70 wrap=soft></textarea>
[philg_hidden_input available_p t]
</table>

<br>
<br>

<center>
<input type=submit value=\"Add Activity\">
</center>


[ad_footer]
"




