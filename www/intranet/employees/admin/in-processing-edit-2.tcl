# /www/intranet/employees/admin/in-processing-edit-2.tcl

ad_page_contract {
    @author teadams@arsdigita.com
    @creation-date  April 24, 2000
    @cvs-id in-processing-edit-2.tcl,v 3.4.2.8 2000/08/16 21:24:49 mbryzek Exp
    @param      return_url        The URL to return to
    @param      experience_id     The ID of the experieance
    @param      source_id         The source ID  
    @param      original_job_id   The original job ID

    @param      caller_user_id    The called user ID
    @param      qualification_id  The qualification ID
    @param      department_id     The department ID
} {
    return_url 
    experience_id
    source_id
    original_job_id
    caller_user_id
    qualification_id
    department_id
    start_date:array,date
}
set exception_count 0
set exception_text ""
# the leading zero of a date like 04 makes the formvalue unhappy, so strip it.
# regsub {^0*} ColValue.start%5fdate.day "" ColValue.start%5fdate.day
if { [info exists start_date(date)] } {
    set start_date_date $start_date(date)
} else {
    incr exception_count
    append exception_text "<li> Error with your start date input.  Please reenter."
}

if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}

db_dml doinsert "insert into im_employee_info (user_id, experience_id, source_id, original_job_id, qualification_id, department_id, start_date) select :caller_user_id, :experience_id, :source_id, :original_job_id, :qualification_id , :department_id, :start_date_date from dual where not exists (select user_id from im_employee_info where user_id = :caller_user_id)"

if {[db_resultrows] == 0} {
    db_dml doupdate "update im_employee_info set experience_id = :experience_id, source_id = :source_id, original_job_id = :original_job_id,  start_date = :start_date_date, qualification_id = :qualification_id, department_id = :department_id where user_id =  :caller_user_id"
}

if {![empty_string_p $start_date_date]} {
    # put this person in the allocation table if he/she is not already
    db_dml add_to_allocation_table "insert into im_employee_percentage_time (start_block, user_id, percentage_time) select start_block, :caller_user_id, '100' from im_start_blocks where start_block > (select max(start_block) from im_start_blocks where start_block < :start_date_date) and not exists (select user_id from im_employee_percentage_time where user_id = :caller_user_id)"
}

ad_returnredirect $return_url




