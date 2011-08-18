# $Id: add-2.tcl,v 3.0.4.2 2000/04/28 15:11:11 carsten Exp $
# File: /www/intranet/vacations/add-2.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Purpose: Stores info about absences to the db
#

#This file should be called add-2.tcl
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
if {![info exists contact_info] || [empty_string_p $contact_info]} {
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
# Now we'll do the insertion in the user_vacations table.
set db [ns_db gethandle]
if [catch {ns_db dml $db "insert into user_vacations
      (vacation_id, last_modified, user_id, start_date, end_date, description, contact_info, receive_email_p, vacation_type)
      values
      ($vacation_id, sysdate, $user_id, to_date('$start_date','YYYY-MM-DD'), to_date('$end_date','YYYY-MM-DD'), '$QQdescription', '$QQcontact_info', '$receive_email_p', '$QQvacation_type')" } errmsg] {
	  # Oracle choked on the insert    
	  
	  # see if this is a double click

	  set number_vacations [database_to_tcl_string $db "select count(vacation_id) from 
user_vacations where vacation_id = $vacation_id"]

         if {$number_vacations == 0} {

	     ad_return_error "Error in insert" "We were unable to do your insert in the database. 
	     Here is the error that was returned:
<p>
<blockquote>
<pre>
$errmsg
</pre>
</blockquote>"
	     return
    }
}

ad_returnredirect "index.tcl"
