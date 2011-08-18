# $Id: edit-2.tcl,v 3.0.4.2 2000/04/28 15:11:12 carsten Exp $
# File: /www/intranet/vacations/edit-2.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Purpose: writes absence edits to db
#

#This file should be called edit-2.tcl
set_the_usual_form_variables

# vacation_id, start_date, end_date, description, contact_info, user_id, receive_email_p

#Now check to see if the input is good as directed by the page designer

set exception_count 0
set exception_text ""


# it doesn't matter what instructions we got,
#  since start_date is of type date and thus must be checked.
if [catch { ns_dbformvalue [ns_conn form] start_date date start_date } errmsg] {
        incr exception_count
        append exception_text "<li>Please enter a valid date for the entry date."
}

# it doesn't matter what instructions we got,
#  since end_date is of type date and thus must be checked.
if [catch { ns_dbformvalue [ns_conn form] end_date date end_date } errmsg] {
        incr exception_count
        append exception_text "<li>Please enter a valid date for the entry date."
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

set db [ns_db gethandle]

if [catch {ns_db dml $db "update user_vacations 
      set last_modified = sysdate, start_date = to_date('$start_date','YYYY-MM-DD'), end_date = to_date('$end_date','YYYY-MM-DD'), description = '$QQdescription', contact_info = '$QQcontact_info', user_id = $user_id, receive_email_p = '$receive_email_p', vacation_type = '$QQvacation_type'
      where vacation_id = $vacation_id" } errmsg] {

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

ad_returnredirect "index.tcl"
