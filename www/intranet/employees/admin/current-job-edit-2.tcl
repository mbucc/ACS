# /www/intranet/employees/admin/current-job-edit-2.tcl
# 
# 
# 
# teadams on April 24, 2000
#  by 
#
# current-job-edit-2.tcl,v 3.2.2.4 2000/08/16 21:24:48 mbryzek Exp
# /www/intranet/employees/admin/current-job-edit-2.tcl

ad_page_contract {
    Sets a users' current job title  

    @author teadams@arsdigita.com
    @creation-date 5/28/2000
    @cvs-id current-job-edit-2.tcl,v 3.2.2.4 2000/08/16 21:24:48 mbryzek Exp
    @param return_url The url to jump back to after
    @param user_id The user we're looking at
    @param current_job_id The id of the job we're dealing with
} {
    { return_url "" } 
    { user_id:integer "" }
    { current_job_id:integer "" }
}





db_dml update_title "update im_employee_info set current_job_id = :current_job_id where user_id = :user_id"



if { ![empty_string_p $return_url] } {
    ad_returnredirect $return_url
} else {
    ad_returnredirect view?[export_url_vars user_id]
}
