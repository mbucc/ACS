#
# /www/education/subject/admin/edit-3.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this is a confirmation page to allow the user to review their proposed
# changes to the subject properties
#

ad_page_variables {
    subject_name
    subject_id
    {description ""}
    {credit_hours ""}
    {prerequisites ""}
    {professors_in_charge ""}
}


# check and make sure we received all of the input we were supposed to

set exception_text ""
set exception_count 0

if {[empty_string_p $subject_name]} {
    append exception_text "<li> You must provide a name for the new subject."
    incr exception_count
}

if {[empty_string_p $subject_id]} {
    append exception_text "<li> You must provide an identification number for the new subject."
    incr exception_count
}


if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}


set db [ns_db gethandle]

# set the user_id

set user_id [edu_subject_admin_security_check $db $subject_id]


ns_db dml $db "update edu_subjects 
                  set subject_name = '$QQsubject_name',
                      description = '$QQdescription',
                      credit_hours = '$QQcredit_hours',
                      prerequisites = '$QQprerequisites',
                      professors_in_charge = '$QQprofessors_in_charge',
    	              last_modified = sysdate,
                      last_modifying_user = $user_id,
                      modified_ip_address = '[ns_conn peeraddr]'                      
                where subject_id = $subject_id"


ns_db releasehandle $db

ad_returnredirect "index.tcl?subject_id=$subject_id"




