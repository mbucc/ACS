# www/calendar/post-new-2.tcl
ad_page_contract {
    Step 2/4 in adding a new calendar event - Entry Form

    Number of queries: 2

    @author Philip Greenspun (philg@mit.edu)
    @author Sarah Ahmed (ahmeds@arsdigita.com)
    @creation-date 1998-11-18
    @cvs-id post-new-2.tcl,v 3.5.2.6 2000/09/22 01:37:05 kevin Exp

} {
    category
    category_id:naturalnum
    {scope public}
    {user_id:naturalnum ""}
    {group_id:naturalnum ""}
    {on_what_id:naturalnum ""}
    {on_which_group:naturalnum ""}
}


# Purpose:  at this point, we know what kind of event is being described
#           and can potentially do something with that information

# category
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}


ad_scope_error_check

ad_scope_authorize $scope all group_member registered


if { [ad_parameter ApprovalPolicy calendar] == "open"} {
    set verb "Post"
} elseif { [ad_parameter ApprovalPolicy calendar] == "wait"} {
    set verb "Suggest"
} else {
    ad_returnredirect "index.tcl?[export_url_scope_vars]"
    return
}


set page_content "
[ad_scope_header "$verb Event in $category"]
<h2>$verb Event in <i>$category</i></h2>
[ad_scope_context_bar_ws_or_index [list "index.tcl?[export_url_scope_vars]" [ad_parameter SystemName calendar "Calendar"]] "$verb Event"]

<hr>
[ad_scope_navbar]

<form method=post action=\"post-new-3\">
[export_form_scope_vars category category_id]
<h3>Event Title</h3>

<p>

Title: <input type=text size=60 MAXLENGTH=100 name=title>

<h3>Full Description</h3>

Make sure to include event hours, e.g., \"10 am to 4 pm\" and
directions to the event.

<p>

<textarea cols=70 rows=10 wrap=soft name=body></textarea>

<P>

Text above is 

<select name=html_p><option value=f>Plain Text<option value=t>HTML</select>
"


## Create date widgets


set param_DaysTillStart [ad_parameter DaysFromPostingToStart calendar 30]
set param_HowLong [ad_parameter DaysFromStartToEnd calendar 0]

db_1row query_dates "
select sysdate + :param_DaysTillStart as start_date,
sysdate + :param_DaysTillStart + :param_HowLong as end_date
from dual"

set start_date_widget [ad_dateentrywidget start_date $start_date]
set end_date_widget [ad_dateentrywidget end_date $end_date]

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

    ## Notice that it is possible for the table to be empty, 
    ## yet the Event Location header would be displayed anyway.
    ## God, I love good software design. -MJS

    if [ad_parameter InternationalP] {
	append page_content "<tr><th align=left>Country<td>[country_widget]</tr>\n"
    }
    if [ad_parameter SomeAmericanReadersP] {
	append page_content "<tr><th align=left>State<td>[state_widget]</tr>\n"
	append page_content "<tr><th align=left>US Zip Code<td><input type=text name=zip_code size=7 MAXLENGTH=10></tr> \n"
    }
    append page_content "</table>\n"
}

append page_content "

<P>

<center>
<input type=\"submit\" value=\"Submit\">
</center>
</form>
[ad_scope_footer]
"

doc_return  200 text/html $page_content

## END FILE post-new-2.tcl