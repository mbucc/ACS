# $Id: poll-new.tcl,v 3.0 2000/02/06 03:27:07 ron Exp $
# poll-new.tcl -- prompt for information about a new poll.

# random preliminaries

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}


set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

# get the poll_id

set db [ns_db gethandle]

set poll_id [database_to_tcl_string $db "select poll_id_sequence.nextval from dual"]

ns_db releasehandle $db


ns_return 200 text/html "

[ad_admin_header "New Poll"]
<h2>New Poll</h2>
[ad_admin_context_bar [list "/admin/poll" Polls] New]
<hr>

<form method=post action=poll-new-2.tcl>

[export_form_vars poll_id]

<table border=0>

<tr>
<td> Poll Name</td>
<td> <input type=text name=name size=50 maxlength=100></td>
</tr>

<tr>
<td valign=top> Poll Description</td>
<td> <textarea name=description rows=5 cols=50 wrap=soft></textarea></td>
</tr>

<tr>
<td> Start Date</td>
<td> [ad_dateentrywidget start_date]</td>
</tr>

<tr>
<td> End Date</td>
<td> [ad_dateentrywidget end_date]</td>
</tr>

<tr>
<td> &nbsp</td>
</tr>

<tr>
<td> </td>
<td> <input type=checkbox name=require_registration_p value=\"t\"> Require Registration </td>
</tr>


</table>

<p>
<center>
<input type=submit value=Create>
</center>
</form>

<p>

[ad_admin_footer]
"

