# $Id: post-new-2.tcl,v 3.2.2.1 2000/04/28 15:09:48 carsten Exp $
# File:     /calendar/post-new-2.tcl
# Date:     1998-11-18
# Contact:  philg@mit.edu, ahmeds@arsdigita.com
# Purpose:  at this point, we know what kind of event is being described
#           and can potentially do something with that information
# x 

set_the_usual_form_variables 0
# category
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)

ad_scope_error_check

set db [ns_db gethandle]
ad_scope_authorize $db $scope all group_member registered

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

if { [ad_parameter ApprovalPolicy calendar] == "open"} {
    set verb "Post"
} elseif { [ad_parameter ApprovalPolicy calendar] == "wait"} {
    set verb "Suggest"
} else {
    ad_returnredirect "index.tcl?[export_url_scope_vars]"
    return
}

ReturnHeaders

ns_write "
[ad_scope_header "$verb $category Item" $db]
<h2>$verb $category Item</h2>
[ad_scope_context_bar_ws_or_index [list "index.tcl?[export_url_scope_vars]" [ad_parameter SystemName calendar "Calendar"]] "$verb Item"]

<hr>
[ad_scope_navbar]

<form method=post action=\"post-new-3.tcl\">
[export_form_scope_vars category]
<h3>The title</h3>

Remember that in a list of events, users will only see the title.  So
try to make the title as descriptive as possible, e.g.,
\"[ad_parameter TitleExample calendar "Ansel Adams show at Getty
Center in Los Angeles, March 1-June 15"]\".  

<p>

Title: <input type=text size=60 name=title>

<h3>Full Description</h3>

This information will be visible to a user who has clicked on a title.
Make sure to include event hours, e.g., \"10 am to 4 pm\" and
directions to the event.

<p>

<textarea cols=70 rows=10 wrap=soft name=body></textarea>

<P>

Text above is 

<select name=html_p><option value=f>Plain Text<option value=t>HTML</select>
"

ns_write "

<h3>Dates</h3>

To ensure that users get relevant and accurate information, the
software is programmed to show only events that are in the future.
Furthermore, these events are sorted by the time that they start.  So
an event that happens next week is given more prominence than an evetn
that happens next year.  Make sure that you get these right!

<p>

<table>
<tr><th>Event Start Date<td>[philg_dateentrywidget start_date [database_to_tcl_string $db "select sysdate + [ad_parameter DaysFromPostingToStart calendar 30] from dual"]]
<tr><th>Event End Date<td>[philg_dateentrywidget end_date [database_to_tcl_string $db "select sysdate + [ad_parameter DaysFromPostingToStart calendar 30] + [ad_parameter DaysFromStartToEnd calendar 0] from dual"]]
</table>


<h3>Additional contact information</h3>

If there are Internet sources for additional information about this
event, enter a URL and/or email address below.

<p>

<table>
<tr><th align=left>Url<td><input type=text name=event_url size=40 value=\"http://\">
</tr>
<tr><th align=left>Contact Email<td><input type=text name=event_email size=30 value=\"\">
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
	ns_write "<tr><th align=left>Country<td>[country_widget $db]</tr>\n"
    }
    if [ad_parameter SomeAmericanReadersP] {
	ns_write "<tr><th align=left>State<td>[state_widget $db]</tr>\n"
	ns_write "<tr><th align=left>US Zip Code<td><input type=text name=zip_code size=7> (5 digits)</tr> \n"
    }
    ns_write "</table>\n"
}

ns_write "

<P>


<center>
<input type=\"submit\" value=\"Submit\">
</center>
</form>
[ad_scope_footer]
"
 
