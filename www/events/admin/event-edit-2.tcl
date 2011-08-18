#actually takes all the stuff from the forms and updates the database
#getting all the form stuff passed in along with the event_id to be changed.

set_the_usual_form_variables
# event_id, venue_id, display_after, max_people
# start_time, end_time, reg_deadline (from date/time entry widgets),
#reg_cancellable_p, reg_needs_approval_p


set db [ns_db gethandle]

# check user input 

set exception_count 0
set exception_text ""


if { [ns_dbformvalue [ns_conn form] start_time datetime start_time_value] <= 0 } {
    incr exception_count
    append exception_text "<li>Strange... couldn't parse the start time.\n"
}

if { [ns_dbformvalue [ns_conn form] end_time datetime end_time_value] <= 0 } {
    incr exception_count
    append exception_text "<li>Strange... couldn't parse the end time.\n"
}

if { [ns_dbformvalue [ns_conn form] reg_deadline datetime reg_deadline_value] <= 0 } {
    incr exception_count
    append exception_text "<li>Strange... couldn't parse the registration deadline.\n"
}


if { ![info exists display_after] || $display_after == "" } {
    incr exception_count
    append exception_text "<li>You forgot to enter a confirmation message.\n"
}

if { [ns_dbformvalue [ns_conn form] start_time datetime start_time_value] <= 0 } {
    incr exception_count
    append exception_text "<li>Strange... couldn't parse the start time.\n"
}
#check the dates
set selection [ns_db 0or1row $db "select 1 from dual 
where to_date('$start_time_value', 'YYYY-MM-DD HH24:MI:SS') < 
to_date('$end_time_value', 'YYYY-MM-DD HH24:MI:SS')
and
to_date('$reg_deadline_value', 'YYYY-MM-DD HH24:MI:SS') <=
to_date('$start_time_value', 'YYYY-MM-DD HH24:MI:SS')

"]
if {[empty_string_p $selection]} {
    incr exception_count
    append exception_text "<li>Please make sure your start time is before your
    end time and your registration deadline is no later than your start time.\n"
}

if {[exists_and_not_null max_people]} {
    if {[catch {set max_people [validate_integer "max_people" $max_people]}]} {
	incr exception_count
	append exception_text "<li>You must enter a number for maximum capacity"
    }
} else {
    set max_people "null"
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}



# ok, so everything is filled in completely; want to insert the info
# into the db

set update_sql "update events_events
set venue_id = $venue_id,
display_after = '$QQdisplay_after',
max_people = $max_people,
start_time = to_date('$start_time_value', 'YYYY-MM-DD HH24:MI:SS'), 
end_time = to_date('$end_time_value', 'YYYY-MM-DD HH24:MI:SS'),
reg_deadline = to_date('$reg_deadline_value', 'YYYY-MM-DD HH24:MI:SS'),
reg_cancellable_p = '$reg_cancellable_p',
reg_needs_approval_p = '$reg_needs_approval_p'
where event_id = $event_id"

ns_db dml $db $update_sql

#if [catch {ns_db dml $db $update_sql} errmsg] {
#    ns_return 200 text/html  "
#<body bgcolor=\"#FFFFFF\">
#<h2>  Error in Updating information</h2> 
#for this <a href=\"event.tcl?event_id=$event_id\">event</a>
#<p>
#Here is the error it reported:
#<p>
#<blockquote>
#$errmsg
#</blockquote>
#</p>
#</html>" }

ns_db releasehandle $db
ad_returnredirect "event.tcl?event_id=$event_id"
