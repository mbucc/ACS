# /www/intranet/absences/edit-2.tcl

ad_page_contract {
    Purpose: writes absence edits to db

    @param vacation_id:integer
    @param description 
    @param vacation_type 
    @param contact_info
    @param user_id
    @param receive_email_p

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000

    @cvs-id edit-2.tcl,v 1.4.2.9 2000/08/16 21:24:32 mbryzek Exp
} {
    {vacation_id:naturalnum ""}
    {description ""}
    {vacation_type ""}
    {start_date:array,date ""}
    {end_date:array,date ""}
    {contact_info ""}
    {user_id ""}
    {receive_email_p ""}
}


# Now check to see if the input is good as directed by the page designer

set exception_count 0
set exception_text ""

# check for null start_date and end_date
if [info exists start_date(date)] {
    set start_absence $start_date(date)
} else {
    incr exception_count
    append exception_text "<li> Please make sure the start date is not empty"
}
if [info exists end_date(date)] {
    set end_absence $end_date(date)
} else {
    incr exception_count
    append exception_text "<li> Please make sure the end date is not empty"
}

# users may forget to increment the year when adding an end-of-year vacation
# which would result in a negative vacation length
if {$exception_count == 0} {
    set duration [db_string start_end_dates_from_dual \
            "select 1 + to_date(:end_absence, 'YYYY-MM-DD') - to_date(:start_absence, 'YYYY-MM-DD') from dual"]
    if {$duration <= 0} {
        incr exception_count
        append exception_text "<li>Please make sure the end date is later than the start date."
    }
}

# we were directed to return an error for contact_info
if {![info exists contact_info] ||[empty_string_p $contact_info]} {
    incr exception_count
    append exception_text "<li>You did not enter a value for contact_info.<br>"
} 
if {[string length $description] > 4000} {
    incr exception_count
    append exception_text "<LI>\"description\" is too long\n"
}

if {[string length $contact_info] > 4000} {
    incr exception_count
    append exception_text "<LI>\"contact_info\" is too long\n"
}

if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}

# So the input is good --
# Now we'll do the update of the user_vacations table.

if [catch {db_dml vacation_update "update user_vacations 
      set last_modified = sysdate, start_date = to_date(:start_absence,'YYYY-MM-DD'), end_date = to_date(:end_absence,'YYYY-MM-DD'), description = :description, contact_info = :contact_info, user_id = :user_id, receive_email_p = :receive_email_p, vacation_type = :vacation_type
      where vacation_id = :vacation_id" } errmsg] {

# Oracle choked on the update
    ad_return_error "Error in update" 
"We were unable to do your update in the database. Here is the error that was returned:
<p>
<blockquote>
<pre>
$errmsg
</pre>
</blockquote>"
    return
}

db_release_unused_handles
ad_returnredirect "index"
