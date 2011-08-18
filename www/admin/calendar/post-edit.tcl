# $Id: post-edit.tcl,v 3.0.4.1 2000/04/28 15:08:27 carsten Exp $
# File:     admin/calendar/post-edit.tcl
# Date:     1998-11-18
# Contact:  philg@mit.edu, ahmeds@arsdigita.com
# Purpose:  calendar item edit page

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set_form_variables 0

# calendar_id

set user_id [ad_get_user_id]
if { $user_id == 0 } {
    ad_returnredirect "/register/index.tcl?return_url=[ns_urlencode [ns_conn url]?[export_url_vars calendar_id]]"
    return
}

set db [ns_db gethandle]

set selection [ns_db 0or1row $db "select title, body, html_p, approved_p, start_date, end_date, expiration_date, decode(event_url,null,'http://',event_url) as event_url, event_email, country_code, usps_abbrev, zip_code, category_id 
from calendar
where calendar_id = $calendar_id"]

if { $selection == "" } {
    ad_return_error "Can't find calendar item" "Can't find news item $calendar_id"
    return
}

set_variables_after_query


ReturnHeaders

ns_write "[ad_admin_header "edit $title"]
<h2>Edit </h2>
item <a href=\"item.tcl?calendar_id=$calendar_id\">$title</a>
<hr>

<form method=post action=\"post-edit-2.tcl\">
<h3>The title</h3>

Remember that in a list of events, users will only see the title.  So
try to make the title as descriptive as possible, e.g.,
\"[ad_parameter TitleExample calendar "Ansel Adams show at Getty
Center in Los Angeles, March 1-June 15"]\".  

<p>

Title: <input type=text size=60 name=title  value=\"[philg_quote_double_quotes $title]\">

<h3>Full Description</h3>

This information will be visible to a user who has clicked on a title.
Make sure to include event hours, e.g., \"10 am to 4 pm\" and
directions to the event.

<p>

<textarea cols=70 rows=10 wrap=soft name=body>[philg_quote_double_quotes $body]</textarea>

<P>

Text above is 

<select name=html_p>
[ad_generic_optionlist {"Plain Text" "HTML"} {"f" "t"} $html_p]
</select>

<h3>Dates</h3>

To ensure that users get relevant and accurate information, the
software is programmed to show only events that are in the future.
Furthermore, these events are sorted by the time that they start.  So
an event that happens next week is given more prominence than an evetn
that happens next year.  Make sure that you get these right!

<p>

<table>
<tr><th>Event Start Date<td>[philg_dateentrywidget start_date $start_date]
<tr><th>Event End Date<td>[philg_dateentrywidget end_date $end_date]
</table>


<h3>Additional contact information</h3>

If there are Internet sources for additional information about this
event, enter a URL and/or email address below.

<p>

<table>
<tr><th align=left>Url<td><input type=text name=event_url size=40 value=\"[philg_quote_double_quotes $event_url]\">
</tr>
<tr><th align=left>Contact Email<td><input type=text name=event_email size=30 value=\"[philg_quote_double_quotes $event_email]\">
</tr>
</table>

"

if [ad_parameter EventsHaveLocationsP calendar 1] {
    ns_write "<h3>Event Location</h3>

If this event can be said to occur in one location, then please tell
us where it is.  This will help our software give special prominence
to events that are geographically close to a particular user.

<p>

Note that this information is not shown to users but only used by our
computer programs. The description above should contain information
about where to find the event.

<p>

<table>
"
    if [ad_parameter InternationalP] {
	if {$country_code == "us"} {
	  ns_write "<tr><th align=left>Country<td>[country_widget $db]</tr>\n"
	} else {
	  ns_write "<tr><th align=left>Country<td>[country_widget $db $country_code]</tr>\n"
	}
    }

    if [ad_parameter SomeAmericanReadersP] {
	ns_write "<tr><th align=left>State<td>[state_widget $db $usps_abbrev]</tr>\n"
	ns_write "<tr><th align=left>US Zip Code<td><input type=text name=zip_code size=7 value=\"[philg_quote_double_quotes $zip_code]\"></tr> (5 digits)\n"
    }
    ns_write "</table>\n"
}

ns_write "

<P>


<center>
<input type=\"submit\" value=\"Submit\">
</center>
[export_form_vars category_id calendar_id]
</form>
[ad_admin_footer]
"







