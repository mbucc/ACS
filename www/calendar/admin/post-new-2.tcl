# www/calendar/admin/post-new-2.tcl
ad_page_contract {
    Step 2/4 in adding a new calendar event - Entry Form

    Number of queries: 3

    @author Philip Greenspun (philg@mit.edu)
    @author Sarah Ahmed (ahmeds@arsdigita.com)
    @creation-date 1998-11-18
    @cvs-id post-new-2.tcl,v 3.2.2.6 2001/01/10 16:35:35 khy Exp
} {
    category_id:notnull,naturalnum
    category
    {scope public}
    {user_id:naturalnum ""}
    {group_id:naturalnum ""}
    {on_what_id:naturalnum ""}
    {on_which_group:naturalnum ""}
}

# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

# category
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)


ad_scope_error_check

set user_id [ad_scope_authorize $scope admin group_admin none]


if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}


## Alright, let's see that abstraction!!
set verb "Post"

set page_content "
[ad_scope_admin_header "$verb Event in $category"]
[ad_scope_admin_page_title "$verb Event in <i>$category</i>"]
[ad_scope_admin_context_bar [list "index.tcl?[export_url_scope_vars]" "Calendar"] "$verb Event"]

<hr>

<form method=post action=\"post-new-3\">
<h3>Event Title</h3>

<p>

Title: <input type=text size=60 MAXLENGTH=100 name=title>

<h3>Full Description</h3>

Make sure to include event hours, e.g., \"10 am to 4 pm\" 
and directions to the event.

<p>

<textarea cols=70 rows=10 wrap=soft name=body></textarea>

<P>

Text above is 

<select name=html_p><option value=f>Plain Text<option value=t>HTML</select>
"


set calendar_id [db_nextval "calendar_id_sequence"]


## Create date widgets

set param_DaysTillStart [ad_parameter DaysFromPostingToStart calendar 30]
set param_HowLong [ad_parameter DaysFromStartToEnd calendar 0]

set query_start_date "select sysdate + $param_DaysTillStart as start_date from dual"
set query_end_date "select sysdate + $param_DaysTillStart + $param_HowLong from dual"

set start_date_widget [ad_dateentrywidget start_date [db_string start_date $query_start_date]]
set end_date_widget [ad_dateentrywidget end_date [db_string end_date $query_end_date]]

db_release_unused_handles



append page_content "

<h3>Dates</h3>

<table>
<tr><th>Start Date<td>$start_date_widget
<tr><th>End Date<td>$end_date_widget
</table>

<h3>Additional contact information</h3>

<p>If there is an Internet source for additional information about this
event, then enter the URL.</p>

<p>Internet URL:<br>
<input type=text name=event_url size=80 MAXLENGTH=200 value=\"http://\"></p>


<P>If attendees can reach an event coordinator via email, then enter the address below.</p>

<p>Contact Email:<br>
<input type=text name=event_email size=50 MAXLENGTH=100 value=\"\"></p>

"

if [ad_parameter EventsHaveLocationsP calendar 1] {
    append page_content "<h3>Event Location</h3>

<p>This information is not displayed to the user, and is optional.</p>

<table>
"
    if [ad_parameter InternationalP] {
	append page_content "<tr><th align=left>Country<td>[country_widget]</tr>\n"
    }
    if [ad_parameter SomeAmericanReadersP] {
	append page_content "<tr><th align=left>State<td>[state_widget]</tr>\n"
	append page_content "<tr><th align=left>US Zip Code<td><input type=text name=zip_code size=7 MAXLENGTH=10></tr>\n"
    }
    append page_content "</table>\n"
}

append page_content "

<P>

<center>
<input type=\"submit\" value=\"Submit\">
</center>
[export_form_scope_vars category_id]
[export_form_vars -sign calendar_id]
</form>
[ad_scope_admin_footer]
"
 
doc_return  200 text/html $page_content

## END FILE post-new-2.tcl

