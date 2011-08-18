# $Id: poll-edit-2.tcl,v 3.0.4.1 2000/04/28 15:09:15 carsten Exp $
# poll-edit-2.tcl -- commit changes to a poll

set_the_usual_form_variables
# expects poll_id name, description, start_date, end_date, require_registration_p


# expects poll_id name, description, start_date, end_date, require_registration_p


# random preliminaries

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

# sanity check

set exception_count 0
set exception_text ""

if { ![info exists poll_id] || [empty_string_p $poll_id] } {
    incr exception_count
    append exception_text "<li> poll_id is missing.  This could mean there's a problem in our software"
}

if { ![info exists name] || [empty_string_p $name] } {
    incr exception_count
    append exception_text "<li> Please supply a poll name"
}

if { ![info exists description] || [empty_string_p $description] } {
    incr exception_count
    append exception_text "<li> Please supply a description"
}


if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}


# prep the date and checkbox inputs

ns_dbformvalue [ns_getform] start_date date start_date
ns_dbformvalue [ns_getform] end_date date end_date

if { ![info exists require_registration_p] || ($require_registration_p != "t") } {
    set require_registration_p "f"
}


# now update it

set update_sql "
update polls set
    name = '$QQname',
    description = '$QQdescription',
    start_date = '$start_date',
    end_date = '$end_date',
    require_registration_p = '$require_registration_p'
where
    poll_id = $poll_id
"

set db [ns_db gethandle]

if [catch { ns_db dml $db $update_sql } errmsg ] {
    ns_return 200 text/html "
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

# Update the memoized value

util_memoize_flush "poll_info_internal $poll_id"

# redirect back to the index

ad_returnredirect "index.tcl"

