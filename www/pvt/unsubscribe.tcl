# $Id: unsubscribe.tcl,v 3.0.4.1 2000/03/15 05:52:29 hqm Exp $

set user_id [ad_get_user_id]

set db [ns_db gethandle]

set selection [ns_db 1row $db "select on_vacation_until, on_vacation_p(on_vacation_until) as on_vacation_p 
from users
where user_id = $user_id"]
set_variables_after_query

ReturnHeaders
ns_write "[ad_header "Confirm Unsubscribe"]

<h2>Confirm</h2>

that you'd like to unsubscribe from [ad_site_home_link]

<hr>

"

if { $on_vacation_p == "t" } {
    ns_write "You are current marked as being on vacation until [util_AnsiDatetoPrettyDate $on_vacation_until].  If you'd like to start receiving email alerts again, just <a href=\"set-on-vacation-to-null.tcl\">tell us that you're back</a>."
} else {
    ns_write "If you are interested in this community but wish to stop receiving
email then you might want to 

<ul>
<li>tell the system that you're going on vacation until 
<form method=get action=set-on-vacation-until.tcl>
[philg_dateentrywidget_default_to_today on_vacation_until]
<input type=submit value=\"Put email on hold\">
</form>
<p>
"
}

set selection [ns_db 0or1row $db "select dont_spam_me_p from users_preferences where user_id = $user_id"]

if { $selection != "" } {
    set_variables_after_query
    if { $dont_spam_me_p != "t" } {
	ns_write "
<li>The system is currently set to send you email notifications. Click here to  <a href=\"toggle-dont-spam-me-p.tcl\">tell the system not to send you any email notifications</a>.
"
    } else {
	ns_write "
<li>The system is currently set to <i>not</i> send you any email notifications. Click here <a href=\"toggle-dont-spam-me-p.tcl\">allow system to send you email notifications</a>.
"	
  }
}

ns_write "


</ul>

<p>

However, if you've totally lost interest in this community or topic,
then you can <a href=\"unsubscribe-2.tcl\">ask the server to mark your
account as deleted</a>.

[ad_footer]"
