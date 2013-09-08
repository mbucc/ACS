# poll-edit-2.tcl

ad_page_contract {
    Commit changes to a poll.

    @param poll_id the ID of the poll
    @param name the name of the poll
    @param description the description given for the poll
    @param start_date the date that the poll begins
    @param end_date the date that the poll ends
    @param require_registration_p does this poll require registration?
    
    @cvs-id poll-edit-2.tcl,v 3.3.2.9 2000/09/22 01:35:47 kevin Exp
} {
    poll_id:notnull,naturalnum
    name:notnull
    description:notnull
    start_date:array,date
    end_date:array,date
    {require_registration_p "f"}
}


# random preliminaries

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set starting $start_date(date)
set ending $end_date(date)

# prep the date and checkbox inputs

if { [db_string get_date_in_correct_order "select 1 from dual where :starting < :ending" -default "0"] != 1} {
    ad_return_complaint 1 "Start date is after or the same as end date"
    return
}

# now update it

set update_sql "
update polls set
    name = :name,
    description = :description,
    start_date = :starting,
    end_date = :ending,
    require_registration_p = :require_registration_p
where
    poll_id = :poll_id
"



if [catch { db_dml update_poll $update_sql } errmsg ] {
    doc_return  200 text/html "
[ad_admin_header "Error updating poll"]
<h3>Error while updating a poll</h3>
<hr>
There was an error in updating the poll.  Here is
what the database returned:
<p>
<pre>
$errmsg
</pre>
[ad_admin_footer]
"
    return
}

db_release_unused_handles

# Update the memoized value

util_memoize_flush "poll_info_internal $poll_id"

# redirect back to the index

ad_returnredirect ""

