# File:  events/admin/event-edit-2.tcl
# Owner: bryanche@arsdigita.com
# Purpose:  updates the database with edited event info, verifying first. 
#####

ad_page_contract {
    Updates the database with edited event info, verifying first. 
 
    @param event_id the event_id to create
    @param display_after a registration confirmation message
    @param reg_cancellable_p can this event be canceled
    @param contact_user_id the event's contact person
    @param max_people the max number of people that can register for this event
    @param reg_needs_approval_p does a registration need to be approved?
    @param reg_cancellable_p can a registration be canceled
    @param venue_id the event's venue

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id event-edit-2.tcl,v 3.9.2.7 2000/09/22 01:37:36 kevin Exp
} {
    {event_id:naturalnum,notnull}
    {display_after:html,trim,notnull}
    {reg_cancellable_p}
    {contact_user_id:naturalnum,notnull}
    {max_people:naturalnum,optional [db_null]}
    {reg_needs_approval_p}
    {venue_id:naturalnum,notnull}
}



### check user input 
set exception_count 0
set exception_text ""

if { [catch {ns_dbformvalue [ns_conn form] reg_deadline datetime reg_deadline_value} err_msg]} {
    incr exception_count
    append exception_text "<li>Please enter a valid registration deadline.\n"
}
if { [catch {ns_dbformvalue [ns_conn form] start_time datetime start_time_value} err_msg]} {
    incr exception_count
    append exception_text "<li>Please enter a valid start time.\n"
}
if { [catch {ns_dbformvalue [ns_conn form] end_time datetime end_time_value} err_msg]} {
    incr exception_count
    append exception_text "<li>Please enter a valid end time.\n"
}

## return with errors, if any.
if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

## Date checking 
set time_check [db_0or1row check_time "select '1_time_check' from dual 
   where to_date(:start_time_value, 'YYYY-MM-DD HH24:MI:SS')  
           < to_date(:end_time_value, 'YYYY-MM-DD HH24:MI:SS')
     and to_date(:reg_deadline_value, 'YYYY-MM-DD HH24:MI:SS') 
           <= to_date(:start_time_value, 'YYYY-MM-DD HH24:MI:SS')
"]
if {!$time_check} {
    ad_return_complaint 1 "<li>Please make sure your start time is before your
    end time and your registration deadline is no later than your start time.\n"
    return
}


set event_group_id [db_string sel_event_group_id "select
group_id from events_events
where event_id = :event_id"]

# ok, so everything is filled in completely; want to insert the info
# into the db

db_transaction {

    set update_sql "update events_events
    set venue_id = :venue_id, display_after = :display_after,
    max_people = :max_people, 
    start_time = to_date(:start_time_value, 'YYYY-MM-DD HH24:MI:SS'), 
    end_time = to_date(:end_time_value, 'YYYY-MM-DD HH24:MI:SS'),
    reg_deadline = to_date(:reg_deadline_value, 'YYYY-MM-DD HH24:MI:SS'),
    reg_cancellable_p = :reg_cancellable_p,
    reg_needs_approval_p = :reg_needs_approval_p
    where event_id = :event_id" 

    db_dml update_events $update_sql

    db_dml unused "update event_info
    set contact_user_id = :contact_user_id
    where group_id = :event_group_id"

}

## should catch that db update someday.
#if [catch {db_dml unused $update_sql} errmsg] {
#    doc_return  200 text/html  "
#<body bgcolor=\"#FFFFFF\">
#<h2>  Error in Updating information</h2> 
#for this <a href=\"event?event_id=$event_id\">event</a>
#<p>
#Here is the error it reported:
#<p>
#<blockquote>
#$errmsg
#</blockquote>
#</p>
#</html>" }

## clean up and redirect to event.tcl.

db_release_unused_handles
ad_returnredirect "event.tcl?event_id=$event_id"

##### EOF
