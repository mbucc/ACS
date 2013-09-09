# /www/intranet/absences/add-2.tcl

ad_page_contract {
    Add a new absence into the database.

    @param vacation_id vacation_id
    @param description description
    @param vacation_type vacation type
    @param start_date start_date
    @param end_date end date
    @param contact_info contact info
    @param user_id user id
    @param receive_email_p  email p
    @param return_url Optional

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date January 2000

    @cvs-id add-2.tcl,v 1.5.2.10 2001/01/12 17:15:16 khy Exp   
} {
    { vacation_id:naturalnum,notnull,verify }
    { description "" }
    { vacation_type "" }
    { start_date:array,date "" }
    { end_date:array,date "" }
    { contact_info "" }
    { user_id "" }
    { receive_email_p "" }
    { return_url "" }
} 

# Now check to see if the input is good as directed by the page designer

set exception_count 0
set exception_text ""

# check for not null start date
if { [info exists start_date(date) ] } {
   set start_absence $start_date(date)
} else {
   incr exception_count
   append exception_text "<li> Please make sure the start date is not empty"
}

# check for not null end date 
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
if {![info exists contact_info] || [empty_string_p [string trim $contact_info]]} {
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

if {[llength [util_GetCheckboxValues [ns_getform] user_id_list ""]] == 0} {
    incr exception_count
    append exception_text "<LI> Please select at least one employee\n"
}

if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}

# So the input is good --
# Now we'll do the insertion in the user_vacations table.


db_transaction {

    set ctr 0
    # initial user_id, will be changed by update in loop
    set user_id 0
    foreach user_id [util_GetCheckboxValues [ns_getform] user_id_list ""] {
	incr ctr
	if { $ctr > 1 } {
	    # We lose double-click protection for multi-users. oh well.
	    set vacation_id [db_string vacation_sequence_nextval \
		    "select user_vacations_vacation_id_seq.nextval from dual"]
	}
	if [catch {db_dml vacation_insert "insert into user_vacations
	(vacation_id, last_modified, user_id, start_date, end_date, description, contact_info, receive_email_p, vacation_type)
	values
        (:vacation_id, sysdate, :user_id, to_date(:start_absence,'YYYY-MM-DD'), to_date(:end_absence,'YYYY-MM-DD'), :description, :contact_info, :receive_email_p, :vacation_type)" } errmsg] {
	    # Oracle choked on the insert    
	    
	    # see if this is a double click
	    
	    set number_vacations [db_string vacation_count "select count(vacation_id) from 
	    user_vacations where vacation_id = $vacation_id"]

	    if {$number_vacations == 0} {
                db_release_unused_handles		
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
    }
}

db_release_unused_handles
if { [exists_and_not_null return_url] } {
    ad_returnredirect $return_url
} else {
    ad_returnredirect "index"
}
