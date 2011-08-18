#
# /www/education/class/admin/solutions-add-edit.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, February 2000
#
# this page allows professors to upload solutions to the assignments
# its action is upload-new.tcl from the file-storage module wiht return_url
# set as solutions-add-edit-2.tcl because we also need to update 
# edu_assignment_solutions table
#

ad_page_variables {
    task_id
    task_type
    {return_url ""}
}

set db [ns_db gethandle]

# gets the class_id.  If the user is not an admin of the class, it
# displays the appropriate error message and returns so that this code
# does not have to check the class_id to make sure it is valid

set id_list [edu_group_security_check $db edu_class "Edit Tasks"]
set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]

# we don't want to use the append command here because that would change
# the acutal value of task_type, which we don't want to do
set task_type_plural ${task_type}s
set task_type_caps [capitalize $task_type]

# lets make sure that the task is in the right class and if of the
# correct type
set selection [ns_db 0or1row $db "select task_name as file_name,
           files.file_id,
           files.version_id,
           files.file_extension,           
           files.url
      from edu_student_tasks t,
           (select ver.file_id, 
                   version_id,
                   file_extension,
                   url,
                   task_id
              from edu_task_solutions sol,  
                   fs_versions_latest ver
             where sol.file_id = ver.file_id
               and sol.task_id = $task_id) files
     where t.task_id = $task_id 
and t.task_type = '$task_type'
and t.task_id = files.task_id(+)
and t.class_id = $class_id"]

if {$selection == ""} {
    ad_return_complaint 1 "<li>The $task_type you have requested does not belong to this class."
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
         and on_which_table = 'FS_VERSIONS'
         and scope = 'group_role'
         and gp.group_id = $class_id
         and permission_type = 'read'
         and gp.group_id = map.group_id
         and lower(gp.role) = lower(map.role)
       order by priority"]

    # we want the lowest priority so lets just grab the first element
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
         and on_which_table = 'FS_VERSIONS'
         and scope = 'group_role'
         and gp.group_id = $class_id
         and permission_type = 'write'
         and gp.group_id = map.group_id
         and lower(gp.role) = lower(map.role)
       order by priority"]

    # we want the lowest priority so lets just grab the first element
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


set version_id [database_to_tcl_string $db "select fs_version_id_seq.nextval from dual"]
set file_title "$file_name Solutions"

if {[empty_string_p $file_id]} {
    set target_url "upload-new.tcl"
    set file_id [database_to_tcl_string $db "select fs_file_id_seq.nextval from dual"]
    set parent_id [database_to_tcl_string $db "select ${task_type}s_folder_id from edu_classes where class_id = $class_id"]
    # we want to pass along the final destination
    set final_return_url $return_url
    set return_url "solutions-add-edit-2.tcl?[export_url_vars task_id file_id final_return_url]"
} else {
    set target_url "upload-version.tcl"
}


set return_string "
[ad_header "Upload Solutions @ [ad_system_name]"]

<h2>Upload Solutions for $file_name</h2>

[ad_context_bar_ws_or_index [list "../one.tcl" "$class_name Home"] [list "" "Administration"] "Upload $task_type_caps Solutions"]

<hr>

<blockquote>

<form enctype=multipart/form-data method=POST action=\"$target_url\">
<table>
[export_form_vars return_url file_id task_id file_title version_id parent_id]

[edu_file_upload_widget $db $class_id $task_type_plural $read_permission_default $write_permission_default]

<tr>
<td colspan=2 align=center>
<br>
<input type=submit value=\"Upload Solutions\">
</td>
</tr>
</table>

</form>

</blockquote>
[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $return_string




