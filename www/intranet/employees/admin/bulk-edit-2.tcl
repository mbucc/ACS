# /www/intranet/employees/admin/bulk-edit-2.tcl

ad_page_contract {
    
    # teadams on April 01, 2000
    # Bulk update the employee info table
    
    @param return_url
    @param experience_id An array of experiance id's indexed on user_id, passed as experience_id_$user_id
    @param source_id  An array of source id's indexed on user_id, passed as source_id_$user_id
    @param original_job_id An array of original job id's indexed on user_id, passed as original_job_id_$user_id
    @param current_job_id An array of current job id's indexed on user_id, passed as current_job_id_$user_id
    @param department_id An array of department id's indexed on user_id, passed as department_id_$user_id
    @param qualification_id An array of qualifications id's indexed on user_id, passed as source_id_$user_id
    
    @author berkeley@arsdigita.com
    @creation-date Tue Jul 11 15:16:22 2000
    @cvs-id bulk-edit-2.tcl,v 3.4.2.9 2000/08/16 21:24:46 mbryzek Exp

} {
    return_url:notnull
    experience_id:array
    source_id:array
    original_job_id:array
    current_job_id:array
    department_id:array
    qualification_id:array
}



set all_arrays [list "experience_id" "source_id" "original_job_id" "current_job_id" "department_id" "qualification_id"]

foreach one_array $all_arrays {
    foreach the_user_id [array names $one_array] {
	set value [lindex [array get $one_array $the_user_id] 1]
	if [db_0or1row check_if_info_exists "select user_id from im_employee_info where user_id = :the_user_id"] {
	    db_dml update_employee "update im_employee_info set $one_array=:value where user_id =:the_user_id "
	} else {
	    db_dml insert_employee "insert into im_employee_info (user_id) values (:the_user_id)"
	    db_dml update_employee "update im_employee_info set $one_array=:value where user_id =:the_user_id "
	}
    }
}

ad_returnredirect $return_url
