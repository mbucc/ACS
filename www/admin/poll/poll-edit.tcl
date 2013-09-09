# /admin/poll/poll-edit.tcl 

ad_page_contract {
    Present the form to edit a single poll

    @param poll_id the ID of the poll
    
    @cvs-id poll-edit.tcl,v 3.2.2.4 2000/09/22 01:35:48 kevin Exp
} {
    poll_id:naturalnum,notnull
}



# random preliminaries

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

db_1row poll_data_get {
select name, description, start_date, end_date, require_registration_p
  from polls
 where poll_id = :poll_id
}

db_release_unused_handles

if { $require_registration_p == "t" } {
    set checked_text "CHECKED"
} else {
    set checked_text ""
}



set page_html "
[ad_admin_header "Edit Poll: $name"]
<h2>Edit Poll: $name</h2>
[ad_admin_context_bar [list "/admin/poll" Polls] Edit]
<hr>
<p>

<form method=post action=poll-edit-2>

[export_form_vars poll_id]

<table border=0>

<tr>
<td> Poll Name</td>
<td> <input type=text name=name size=50 maxlength=100 [export_form_value name]></td>
</tr>

<tr>
<td valign=top> Poll Description</td>
<td> <textarea name=description rows=5 cols=50 wrap=soft>[ns_quotehtml $description]</textarea></td>
</tr>

<tr>
<td> Start Date</td>
<td> [ad_dateentrywidget start_date $start_date]</td>
</tr>

<tr>
<td> End Date</td>
<td> [ad_dateentrywidget end_date $end_date]</td>
</tr>

<tr>
<td> &nbsp</td>
</tr>

<tr>
<td> </td>
<td> <input type=checkbox name=require_registration_p value=\"t\" $checked_text> Require Registration </td>
</tr>

</table>

<p>
<center>
<input type=submit value=Update>
</center>
</form>

<p>
[ad_admin_footer]
"

doc_return  200 text/html $page_html




