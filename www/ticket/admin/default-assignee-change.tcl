# /www/ticket/admin/default-assignee-change.tcl
ad_page_contract {
    Assign a new default assignee to a ticket group

    @param group_id a group to limit the choice of assignees to
    @param domain_id the ID of the domain
    @param project_id the ID of the project
    @param ticket_return
    @param target I do not understand the existance of this variable
    @param passthrough or this one

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @author Kevin Scaldeferri (kevin@caltech.edu)
    @creation-date 15 May 2000
    @cvs-id default-assignee-change.tcl,v 3.3.2.3 2000/09/22 01:39:25 kevin Exp
} {
    group_id:integer,notnull
    domain_id:integer,notnull
    project_id:integer,notnull
    { ticket_return "" }
    { target "" }
    { passthrough "" }
}

# -----------------------------------------------------------------------------

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration


set context [list \
                 [list $ticket_return "Ticket Tracker"] \
                 [list "index.tcl?[export_url_vars project_id ticket_return]" "Administration"] \
                 [list "index.tcl?view=project&[export_url_vars project_id ticket_return]" "One project"] \
                 [list "[ns_conn url]?[export_url_vars ticket_return]" "Select default assignee"]]

doc_return  200 text/html "
[ad_header "[ticket_system_name] - select default assignee"]
 
<h2>[ticket_system_name] - select default assignee</h2>
[ticket_context $context]
<hr>

Locate user by:

<form method=get action=/user-search>
[export_ns_set_vars form [list target passthrough]]
<input type=hidden name=passthrough value=\"domain_id project_id ticket_return\">
<input type=hidden name=limit_to_users_in_group_id [export_form_value group_id]>
<input type=hidden name=target value=\"/ticket/admin/default-assignee-change-2.tcl\">

<table border=0>
<tr><td>Email address:<td><input type=text name=email size=40></tr>
<tr><td colspan=2>or by</tr>
<tr><td>Last name:<td><input type=text name=last_name size=40></tr>
</table>

<p>

<center>
<input type=submit value=Search>
</center>
</form>

[ad_footer]"

