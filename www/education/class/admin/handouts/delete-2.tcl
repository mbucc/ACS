#
# /www/education/class/admin/handouts/delete-2.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, February 2000
#
# this page deletes a handout from edu_handouts but leaves
# the file in fs_files and fs_versions just in case
#


ad_page_variables {
    handout_id
    {return_url ""}
}


set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "Delete Tasks"]
set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]


# the first thing we want to do is check and make sure that 
# the given handout is not null and a part of this class

if {[empty_string_p $handout_id]} {
    ad_return_complaint "<li>You must provide a way to identify your handout."
    return
}

set delete_permission_p [database_to_tcl_string $db "select decode(count(handout_id),0,0,1)
  from edu_handouts,
       (select * from fs_versions_latest 
        where ad_general_permissions.user_has_row_permission_p($user_id, 'write', version_id, 'FS_VERSIONS') = 't') ver
 where class_id = $class_id
   and handout_id = $handout_id
   and edu_handouts.file_id = ver.file_id"]


if {!$delete_permission_p} {
    ad_return_complaint 1 "<li>You do not have permission to delete this handout."
    return
} 


ns_db dml $db "delete from edu_handouts where handout_id = $handout_id"

ns_db releasehandle $db

ad_returnredirect $return_url
