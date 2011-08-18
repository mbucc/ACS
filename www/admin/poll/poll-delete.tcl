# $Id: poll-delete.tcl,v 3.0 2000/02/06 03:27:02 ron Exp $
# poll-delete.tcl
#
# ask for confirmation of deletion of poll

set_form_variables
# expects poll_id


# random preliminaries

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

ad_maybe_redirect_for_registration

# get display stuff

set db [ns_db gethandle]

set selection [ns_db 1row $db "select name, description
from polls
where poll_id = $poll_id"]

set_variables_after_query

set n_votes [database_to_tcl_string $db "select count(*) from poll_user_choices where poll_id = $poll_id"]

ns_db releasehandle $db

ns_return 200 text/html "[ad_admin_header "Confirm Poll Deletion: $name"]

<h2>Confirm Poll Deletion: $name</h2>

[ad_admin_context_bar [list "/admin/poll" Polls] Delete]

<hr>

You have asked to delete poll <b>$name</b> ($description).

<p>

Deleting the poll will delete all $n_votes votes as well.

<ul>

<li><a href=\"index.tcl\">No, Don't delete it</a>

<p>

<li><a href=\"poll-delete-2.tcl?poll_id=$poll_id\">Yes, I'm sure that I want to delete this poll.</a>

</ul>

<p>
[ad_admin_footer]
"
