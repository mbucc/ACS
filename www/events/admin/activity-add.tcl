# File:  events/admin/activity-add.tcl
# Purpose:  Lets admins add a new activity. 
#    Uses events_members_groups_widget to get the owning group.
#####

ad_page_contract {
Lets admins add a new activity. 
Uses events_members_groups_widget to get the owning group.

@param email_from_search email for default contact person
@param user_id_from_search user_id for default contact person

@author Bryan Che (bryanche@arsdigita.com)
@cvs_id activity-add.tcl,v 3.8.6.6 2001/01/10 18:10:44 khy Exp

} {
    {email_from_search:optional ""}
    {user_id_from_search:optional ""}
}

set user_id [ad_maybe_redirect_for_registration]


# build page to return
set whole_page ""

set activity_id [db_string unused "select events_activity_id_sequence.nextval from dual"]

set return_url "/events/admin/activity-add.tcl"

if {[exists_and_not_null email_from_search]} {
    set contact_email $email_from_search
    set default_contact_user_id $user_id_from_search
} else {
    set contact_email "<i>None</i>"
    set default_contact_user_id ""
}

append whole_page "
   [ad_header "Add a new activity"]

<h2>Add a New Activity</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "activities.tcl" Activities] "Add Activity"]
<hr>

<h3>Activity Description</h3>

<form method=post action=activity-add-2>
[export_form_vars -sign activity_id]
[philg_hidden_input creator_id $user_id]

<table>
<tr>
  <th>Activity Name
  <td><input type=text size=30 name=short_name>
<tr>
  <th>Owning Group
  <td>[events_member_groups_widget $user_id]
<tr>
  <th>Details URL:
  <td><input type=text size=30 name=detail_url>
<tr>
  <td colspan=2>(link to page with more details.  Note: If you don't put 
  <i>http://</i> in your url, the link will be a relative link to 
  your own server)
<tr>
  <th>Default Activity Contact Person
  <td>$contact_email <a href=\"activity-contact-find?[export_url_vars return_url]\">Pick a contact person</a> | <a href=\"$return_url\">No Default Contact
<input type=hidden name=default_contact_user_id value=$default_contact_user_id>
"

#<tr>
# <td>Default Price: 
# <td><input type=text size=10 name=default_price value=0>

append whole_page "
<tr>
  <th>Description
  <td><textarea name=description rows=8 cols=70 wrap=soft></textarea>
[philg_hidden_input available_p t]
</table>
<br><br>

<center> <input type=submit value=\"Add Activity\"> </center>

[ad_footer]
"
## clean up.


doc_return  200 text/html $whole_page

##### EOF
