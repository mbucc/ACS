# www/calendar/post-edit.tcl
ad_page_contract {
    Step 1/2 in editing an existing calendar item
    
    Number of queries: 1

    @author Philip Greenspun (philg@mit.edu)
    @author Sarah Ahmed (ahmeds@arsdigita.com)
    @creation-date 1998-11-18
    @cvs-id post-edit.tcl,v 3.2.2.5 2000/09/22 01:37:07 kevin Exp
    
} {
    calendar_id:naturalnum
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

# calendar_id
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)


ad_scope_error_check

ad_scope_authorize $scope admin group_admin none

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}


if { ![db_0or1row get_item "select title, body, html_p, 
approved_p, start_date, end_date, expiration_date, 
decode(event_url,null,'http://',event_url) as event_url, 
event_email, country_code, usps_abbrev, zip_code, category_id 
from calendar
where calendar_id = :calendar_id
"] } {
    
    ad_scope_return_error "Can't find event" "Can't find event $calendar_id"
    return
}

db_release_unused_handles


set page_content "
[ad_scope_admin_header "edit $title"]
[ad_scope_admin_page_title "Edit event <a href=\"item?[export_url_scope_vars calendar_id]\"><i>$title</i></a>"]  
[ad_scope_admin_context_bar [list "index.tcl?[export_url_scope_vars]" "Calendar"] [list "item.tcl?[export_url_scope_vars calendar_id]" "One Event"] "Edit"]
<hr>

<form method=post action=\"post-edit-2\">
<h3>The title</h3>

Title: <input type=text size=60 MAXLENGTH=100 name=title  value=\"[philg_quote_double_quotes $title]\">

<h3>Full Description</h3>

Make sure to include event hours, e.g., \"10 am to 4 pm\" and
directions to the event.

<p>

<textarea cols=70 rows=10 wrap=soft name=body>
[philg_quote_double_quotes $body]</textarea>

<P>

Text above is 

<select name=html_p>
[ad_generic_optionlist {"Plain Text" "HTML"} {"f" "t"} $html_p]
</select>

<h3>Dates</h3>

<table>
<tr><th>Start Date<td>[ad_dateentrywidget start_date $start_date]
<tr><th>End Date<td>[ad_dateentrywidget end_date $end_date]
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

<P>This information is not displayed to the user, and is optional.</p>

<table>
"
    if [ad_parameter InternationalP] {
	if {$country_code == "us"} {
	  append page_content "<tr><th align=left>Country<td>[country_widget]</tr>\n"
	} else {
	  append page_content "<tr><th align=left>Country<td>[country_widget $country_code]</tr>\n"
	}
    }

    if [ad_parameter SomeAmericanReadersP] {
	append page_content "<tr><th align=left>State<td>[state_widget $usps_abbrev]</tr>\n"
	append page_content "<tr><th align=left>US Zip Code<td>
	<input type=text name=zip_code size=7 MAXLENGTH=10 value=\"[philg_quote_double_quotes $zip_code]\"></tr> (5 digits)\n"
    }
    append page_content "</table>\n"
}

append page_content "

<P>

<center>
<input type=\"submit\" value=\"Submit\">
</center>
[export_form_scope_vars category_id calendar_id]
</form>
[ad_scope_admin_footer]
"

doc_return  200 text/html $page_content

## END FILE post-edit.tcl
