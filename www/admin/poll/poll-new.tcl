# /admin/poll/poll-new.tcl 

ad_page_contract {
    Prompt for information about a new poll.

    @author Original Author Unknown
    @creation-date Original Date Unknown
    @cvs-id poll-new.tcl,v 3.2.2.5 2001/01/11 20:11:11 khy Exp
} {
}

# random preliminaries

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

# get the poll_id

set poll_id [db_string select_new_poll_id "select poll_id_sequence.nextval from dual"]



doc_return  200 text/html "

[ad_admin_header "New Poll"]
<h2>New Poll</h2>
[ad_admin_context_bar [list "/admin/poll" Polls] New]
<hr>

<form method=post action=poll-new-2>

[export_form_vars -sign poll_id]

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

