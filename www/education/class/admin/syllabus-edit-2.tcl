#
# /www/education/class/admin/syllabus-edit-2.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu
#
# this page update the class_info table to reflect the new syllabus
#

ad_page_variables {
    file_id
}

set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "Edit Tasks"]
set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]

# make sure the person has permission to edit the syllabus

set version_id [database_to_tcl_string $db "select version_id from fs_versions_latest where file_id = $file_id"]

if {! [fs_check_write_p $db $user_id $version_id $class_id]} {
    incr exception_count
    append exception_text "<li>You can't write into this file"
}


# the file upload has already been taken care of by either
# upload-new.tcl or upload-version.tcl

ns_db dml $db "update edu_class_info 
               set syllabus_id = $file_id, 
  	           last_modified = sysdate,
                   last_modifying_user = $user_id,
                   modified_ip_address = '[ns_conn peeraddr]'                       
             where group_id = $class_id"

ns_db releasehandle $db

ad_returnredirect ""







