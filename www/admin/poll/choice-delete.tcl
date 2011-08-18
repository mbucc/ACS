# $Id: choice-delete.tcl,v 3.1.4.1 2000/04/28 15:09:13 carsten Exp $
# choice-delete.tcl  Nuke a choice.
#
# since choices are light-weight, don't require confirmation


set_form_variables

# expects choice_id, poll_id

set db [ns_db gethandle]

set delete_sql "
delete from poll_choices
  where choice_id = $choice_id
"

if [catch { ns_db dml $db $delete_sql } errmsg ] {
    ad_return_error "Error deleting choice" "Here is
what the database returned:
<p>
<blockquote>
<pre>
$errmsg
</pre>
</blockquote>

Probably this is because users have already recorded results for this
choice.
"
    return
}

# update memoized choices

validate_integer "poll_id" $poll_id
util_memoize_flush "poll_labels_internal $poll_id"

ad_returnredirect "one-poll.tcl?[export_url_vars poll_id]"


