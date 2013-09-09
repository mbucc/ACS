ad_page_contract {
    Finds a contact person for an event or activity

    @param return_url the url to which to return after this page
    @param event_id the event to which to add a contact if editing an event
    @param activity_id the activity of the new event to which to add a contact
    @param venue_id the venue of the new event to which to add a contact

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id event-contact-find.tcl,v 3.3.6.3 2000/09/22 01:37:36 kevin Exp
} {
    {return_url:notnull}
    {event_id:integer,optional}
    {activity_id:integer,optional}
    {venue_id:integer,optional}
}

page_validation {
    set err_msg ""

    if {![exists_and_not_null event_id]} {
	#there is no event_id, so must be from event-add-2.tcl
	if {![exists_and_not_null activity_id]} {
	    append err_msg "<li>This page came in without an activity_id"
	}
	if {![exists_and_not_null venue_id]} {
	    append err_msg "<li>This page came in without a venue_id"
	}
	
	if {![empty_string_p $err_msg]} {
	    error $err_msg
	}
	set export_vars_html "
	<input type=hidden name=activity_id value=$activity_id>
	<input type=hidden name=venue_id value=$venue_id>
	<input type=hidden name=passthrough value=\"[list activity_id venue_id]\">"
    } else {
	#else, this is from event-edit.tcl, so all is ok
	set export_vars_html "
	<input type=hidden name=event_id value=$event_id>
	<input type=hidden name=passthrough value=\"event_id\">"
    }	
}

doc_return  200 text/html "
[ad_header "Pick a Contact Person"]
<h2>Pick a Contact Person</h2>
<hr>
<form action=\"/user-search\" method=get>
<input type=hidden name=target value=\"$return_url\">
<input type=hidden name=custom_title value=\"Choose a Contact Person for Your Event\">
$export_vars_html
<P>
<h3>Identify Contact Person</h3>
<p>
Search for a user to be the contact person for your event:<br>
<table border=0>
<tr><td>Email address:<td><input type=text name=email size=40></tr>
<tr><td colspan=2>or by</tr>
<tr><td>Last name:<td><input type=text name=last_name size=40></tr>
</table>
<p>
<center>
<input type=submit value=\"Search for a contact person\">
</center>
</form>
<p>
[ad_footer]
"
