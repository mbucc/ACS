# File:  events/admin/activity-edit.tcl
# Owner: bryanche@arsdigita.com
# Purpose:  Allows admins to edit an activity's properties.
#   Note:   Should also allow editing of default price. see a-e-2.tcl.
#####

ad_page_contract {
    Allows admins to edit an activity's properties.

    @param activity_id the activity to edit
    @param email_from_search optional default contact person's email
    @param user_id_from_search optional default contact person's user_id
    @param no_contact_flat optional flag stating there is not default contact
    @param default_contact_user_id optional default contact person's user_id

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs-id activity-edit.tcl,v 3.8.2.7 2000/09/29 14:49:46 bryanche Exp
} {
    {activity_id:naturalnum,notnull}
    {email_from_search:optional}
    {user_id_from_search:optional}
    {no_contact_flag:optional}
    {default_contact_user_id:naturalnum,optional}
}


set user_id [ad_maybe_redirect_for_registration]

set whole_page ""

db_1row activity_info_select "
select short_name, description, available_p,
u.first_names || ' ' || u.last_name as creator_name,
detail_url, group_id,
default_contact_user_id
from events_activities, users u
where activity_id = :activity_id
and creator_id = u.user_id "

if {[exists_and_not_null default_contact_user_id]} {
    set default_contact [db_string contact_email "select
    email from users where user_id = :default_contact_user_id"]
} else {
    set default_contact ""
}

#see if the contact email came from a search
if {[exists_and_not_null email_from_search]} {
    set contact_email $email_from_search
    set default_contact_user_id $user_id_from_search
} elseif {[exists_and_not_null no_contact_flag]} {
    set contact_email "<i>none</i>"
    set default_contact_user_id ""
} elseif {[exists_and_not_null default_contact_user_id]} {
    set contact_email [db_string email_select "select
    email from users where user_id = :default_contact_user_id"]
} else {
    set contact_email "<i>none</i>"
    set default_contact_user_id ""
}

db_release_unused_handles

set return_url "/events/admin/activity-edit.tcl"
set no_contact_flag 1

append whole_page "[ad_header "Edit $short_name"]

<h2>Edit $short_name</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "activities.tcl" Activities] [list "activity.tcl?[export_url_vars activity_id]" Activity] "Edit Activity"]
<hr>

<h3>Activity Description</h3>

<form method=post action=activity-edit-2>
[philg_hidden_input activity_id $activity_id]

<table>
<tr>
  <td>Activity Name
  <td><input type=text size=30 name=short_name value=\"[philg_quote_double_quotes $short_name]\">
<tr>
  <td>Creator
  <td>$creator_name
<tr>
 <td>Default Contact Person
 <td>$contact_email <a href=\"activity-contact-find?[export_url_vars return_url activity_id]\">Pick a different contact person</a> | <a href=\"activity-edit?[export_url_vars activity_id no_contact_flag]\">No Default Contact
<input type=hidden name=default_contact_user_id value=$default_contact_user_id>
<tr>
  <td>Owning Group
  <td>[events_member_groups_widget $user_id $group_id]
<tr>
"

# <td>Default Price
# <td><input type=text size=10 name=default_price value=\"$default_price\">

append whole_page "
<tr>
 <td>URL
 <td><input type=text size=30 name=detail_url value=\"$detail_url\">
<tr>
 <td colspan=2>(Note: If you don't put <i>http://</i> in your url, 
 the link will be a relative link to your own server
<tr>
  <td>Description
  <td><textarea name=description rows=8 cols=70 wrap=soft>$description</textarea>
<tr>
  <td>Current or Discontinued
"

if {$available_p == "t"} {
    append whole_page "
  <td><input type=radio name=available_p value=t CHECKED>Current
      <input type=radio name=available_p value=f>Discontinued
    "
} else {
    append whole_page "
  <td><input type=radio name=available_p value=t>Current
      <input type=radio name=available_p value=f CHECKED>Discontinued
    "
}
append whole_page "
</table>
Note: Discontinuing an activity will not cancel an activity's 
existing events. It only prevents you from adding <i>new</i> events 
to the activity.
<br><br>

<center> <input type=submit value=\"Edit Activity\"> </center>
</form>

[ad_footer]
"
## clean up.


doc_return  200 text/html $whole_page

##### EOF
