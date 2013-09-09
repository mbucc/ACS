# /admin/poll/poll-new-2.tcl

ad_page_contract {
    Add a new poll to the database

    @param poll_id the ID
    @param name name of the poll
    @param description the description of the poll
    @param start_date date the poll begins
    @param end_date dat the poll ends
    @param require_registration_p does this poll require registration?

    @cvs-id poll-new-2.tcl,v 3.3.2.9 2001/01/11 20:10:46 khy Exp
} {
    poll_id:notnull,naturalnum,verify
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
if { $user_id == 0 } {
    ad_returnredirect "/register/?return_url=[ns_urlencode [ns_conn url]]"
    return
}

# prep the date and checkbox inputs

set starting $start_date(date)
set ending $end_date(date)

if { ![info exists require_registration_p] || ($require_registration_p != "t") } {
    set require_registration_p "f"
}
if { [db_string get_date_in_correct_order "select 1 from dual where :starting < :ending" -default "0"] != 1} {
    ad_return_complaint 1 "Start date is after or the same as end date"
    return
}


# now actually put it into the database

set insert_sql "
insert into polls
    (poll_id, name, description,
     start_date, end_date, require_registration_p)
values
    (:poll_id, :name, :description,
     :starting, :ending, :require_registration_p)
"



if [catch { db_dml insert_new_poll $insert_sql } errmsg ] {
    doc_return  200 text/html "
[ad_admin_header "Error inserting poll"]
<h3>Error in inserting a poll</h3>
<hr>
There was an error in inserting the poll.  Here is
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

# redirect to a page where they can enter the poll
# questions

ad_returnredirect "one-poll?[export_url_vars poll_id]"

