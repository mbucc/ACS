# /admin/poll/poll-delete.tcl

ad_page_contract {
    Ask for confirmation of deletion of poll

    @param poll_id the ID of the poll
    @cvs-id poll-delete.tcl,v 3.2.2.4 2000/09/22 01:35:47 kevin Exp
} {
    poll_id:naturalnum,notnull
}

# random preliminaries

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

ad_maybe_redirect_for_registration

# get display stuff



db_1row poll_get_info "select name, description
from polls
where poll_id = :poll_id" 

set n_votes [db_string select_n_votes "select count(*) from poll_user_choices where poll_id = :poll_id"]

db_release_unused_handles

set page_html "[ad_admin_header "Confirm Poll Deletion: $name"]

<h2>Confirm Poll Deletion: $name</h2>

[ad_admin_context_bar [list "/admin/poll" Polls] Delete]

<hr>

You have asked to delete poll <b>$name</b> ($description).

<p>

Deleting the poll will delete all $n_votes votes as well.

<ul>

<li><a href=\"index\">No, Don't delete it</a>

<p>

<li><a href=\"poll-delete-2?poll_id=$poll_id\">Yes, I'm sure that I want to delete this poll.</a>

</ul>

<p>
[ad_admin_footer]
"

doc_return  200 text/html $page_html
