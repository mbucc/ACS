#
# /www/education/class/admin/task-file-new.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu
#
# this file allows a user to upload a new file for an existing task
#

ad_page_variables {
    task_id
    task_type
    {return_url ""}
}    


set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "Edit Tasks"]
set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]


set selection [ns_db 0or1row $db "select task_name as file_title,
               ver.file_id,
               assignments_folder_id as parent_id,
               version_id
          from edu_classes,
               edu_student_tasks,
               fs_versions_latest ver
         where edu_classes.class_id = $class_id
           and edu_student_tasks.class_id = edu_classes.class_id
           and task_id = $task_id
           and edu_student_tasks.file_id = ver.file_id(+)"]

if {$selection == ""} {
    ad_return_complaint 1 "<li>The $task_type you have requested to edit does not belong to this class."
    return
} else {
    set_variables_after_query
}


# in order to determine the defaults for the permissions, we want to see if there
# is already a file for the assignment (or project).  If so, we want to use 
# those as the default


if {[empty_string_p $version_id]} {
    set write_permission_default [edu_get_ta_role_string]
    set read_permission_default ""
} else {
    # lets make sure that they can edit the file
    if {![fs_check_edit_p $db $user_id $version_id $class_id]} {
	ad_return_complaint 1 "<li>You are not authorized to edit this file."
	return
    }

    # more often than not, the scope is going to be group_role so lets
    # try that one first
    set read_permission_default_list [database_to_tcl_list $db "select gp.role
        from general_permissions gp,
             edu_role_pretty_role_map map
       where on_what_id = $version_id
         and lower(on_which_table) = lower('FS_VERSIONS')
         and scope = 'group_role'
         and gp.group_id = $class_id
         and permission_type = 'read'
         and gp.group_id = map.group_id
         and lower(gp.role) = lower(map.role)
       order by priority desc"]

    # we want the highest numerical priority so lets just grab the first element
    set read_permission_default [lindex $read_permission_default_list 0]
    if {[empty_string_p $read_permission_default]} {
	# if there is not a group_role item, we just set our normal default
	# read role of ""
	set read_permission_default ""
    }


    # now, we want to set our default write permissions and we do pretty much
    # the same thing as when we did the read permissions.

    set write_permission_default_list [database_to_tcl_list $db "select gp.role
        from general_permissions gp,
             edu_role_pretty_role_map map
       where on_what_id = $version_id
         and lower(on_which_table) = lower('FS_VERSIONS')
         and scope = 'group_role'
         and gp.group_id = $class_id
         and permission_type = 'write'
         and gp.group_id = map.group_id
         and lower(gp.role) = lower(map.role)
       order by priority desc"]

    # we want the highest numerical priority so lets just grab the first element
    set write_permission_default [lindex $write_permission_default_list 0]
    if {[empty_string_p $write_permission_default]} {
	# there was not a group_role so lets check if it is public
	set write_permission_public_p [database_to_tcl_string_or_null $db "select decode(ad_general_permissions.public_permission_id('write', $version_id, 'FS_VERSIONS'),0,0,1) from dual"]
	if {$write_permission_public_p == 0} {
	    # if write_permisssion_public_p is 0 then there is not a correct permissions
	    # record so we go to our usual default of ta
	    set write_permission_default [edu_get_ta_role_string]
	} 
    }
}

	

if {[empty_string_p $file_id]} {
    set target_url "upload-new.tcl"
    set file_id [database_to_tcl_string $db "select fs_file_id_seq.nextval from dual"]
    set parent_id [database_to_tcl_string $db "select ${task_type}s_folder_id from edu_classes where class_id = $class_id"]
    if {![empty_string_p $return_url]} {
	set return_url "task-add-4.tcl?task_id=$task_id&file_id=$file_id&[export_url_vars return_url]"
    }
} else {
    set target_url "upload-version.tcl"
}

if {[empty_string_p $return_url]} {
    set return_url "[edu_url]/class/admin/task-add-4.tcl?task_id=$task_id&file_id=$file_id"
} 


set version_id [database_to_tcl_string $db "select fs_version_id_seq.nextval from dual"]


set return_string "
[ad_header "Add [capitalize $task_type] File @ [ad_system_name]"]

<h2>Add a File for the [capitalize $task_type]</h2>

[ad_context_bar_ws_or_index [list "../one.tcl" "$class_name Home"] [list "" "Administration"] "Add File for [capitalize $task_type]"]

<hr>

Upload a new file for $file_title.

<form enctype=multipart/form-data method=POST action=\"$target_url\">
[export_form_vars task_id task_type file_id version_id file_title return_url parent_id]
<blockquote>
<table>
[edu_file_upload_widget $db $class_id assignments $read_permission_default $write_permission_default]
</table>
<p>
<center>
Uploading a new file may take a while. Please be patient.
<p>
<input type=submit value=\"Submit File\">
</center>
</blockquote>
</form>

[ad_footer]
"


ns_db releasehandle $db

ns_return 200 text/html $return_string











