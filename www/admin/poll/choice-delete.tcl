# /admin/poll/choice-delete.tcl

# www/admin/poll/choice-delete.tcl
ad_page_contract {
    Deletes one poll choice.
    @param choice_id the ID of the choice to be deleted
    @param poll_id the ID of the poll selected
    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 8 July 2000
    @cvs-id choice-delete.tcl,v 3.4.2.5 2000/09/09 21:05:15 kevin Exp
} {
    choice_id:notnull,naturalnum
    poll_id:notnull,naturalnum
}

set delete_sql "
delete from poll_choices
  where choice_id = :choice_id
"

if [catch { db_dml delete_choice $delete_sql } errmsg ] {
    if {[db_string n_votes "
    select count(*) from poll_user_choices
    where choice_id = :choice_id"] > 0} {
	ad_return_complaint 1 "<li>You cannot delete a choice for which people have already voted."
	return
    } else {
	#something wacky went wrong 
	ad_return_error "Error deleting choice" "
	Something went wrong with the delete. Here is
	what the database returned:
	<p>
	<blockquote>
	<pre>
	$errmsg
	</pre>
	</blockquote>

	"
	return
    }
}

db_release_unused_handles

# update memoized choices

util_memoize_flush "poll_labels_internal $poll_id"

ad_returnredirect "one-poll?[export_url_vars poll_id]"

