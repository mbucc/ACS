#
# /www/education/class/task-turn-in.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, February 2000
#
# this page allows students to upload their answers to tasks
#

ad_page_variables {
    task_id
    task_type
    {return_url one.tcl}
}


set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "Submit Tasks"]
set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]


if {[empty_string_p $task_id]} {
    ad_return_complaint 1 "<li>You must include an task for the solutions."
    return
} 


# lets make sure that the taskis in the class and lets see if this
# is an add or an edit.
set selection [ns_db 0or1row $db "select task_name, 
          answers.file_id,
          url,
          ${task_type}s_folder_id
     from edu_student_tasks tasks, 
          edu_current_classes class,
          (select ans.file_id, 
                 task_id,
                 url
            from edu_student_answers ans,
                 (select * from fs_versions_latest 
                  where ad_general_permissions.user_has_row_permission_p($user_id, 'read', version_id, 'FS_VERSIONS') = 't') ver
            where ver.file_id = ans.file_id
              and ans.student_id = $user_id) answers
    where tasks.task_id = $task_id 
      and tasks.class_id = $class_id
      and tasks.task_id = answers.task_id(+)
      and tasks.class_id = class.class_id"]


if {$selection == ""} {
    ad_return_complaint 1 "The $task_type you have requested does not belong to this class or access to is has been restricted by the course administrator"
    return
} else {
    set_variables_after_query
}



set read_permission [edu_get_ta_role_string]
set write_permission [edu_get_professor_role_string]
	

if {[empty_string_p $file_id]} {
    set target_url "upload-new.tcl"
    set file_id [database_to_tcl_string $db "select fs_file_id_seq.nextval from dual"]
    set return_url "task-turn-in-2.tcl?task_id=$task_id&file_id=$file_id&[export_url_vars return_url]"
} else {
    set target_url "upload-version.tcl"
}


set version_id [database_to_tcl_string $db "select fs_version_id_seq.nextval from dual"]
set file_title "Student Solutions"


set return_string "
[ad_header "Upload Answers @ [ad_system_name]"]

<h2>Upload Answers for $task_name</h2>

[ad_context_bar_ws_or_index [list "" "All Classes"] [list "one.tcl" "$class_name Home"] "Upload Answers"]

<hr>

<blockquote>

<form enctype=multipart/form-data method=POST action=\"$target_url\">

[export_form_vars return_url file_id version_id read_permission write_permission parent_id file_title]

<table>
<tr>
<td valign=top align=right><Br>URL: </td>
<td><br><input type=input name=url value=\"\" size=40> (make sure to include the http://)</td>
</tr>

<tr>
<td valign=top align=right><EM>or</EM> filename: </td>
<td><input type=file name=upload_file size=20>
<Br><FONT SIZE=-1>Use the \"Browse...\" button to locate your file, then click \"Open\".
</FONT><br><Br></td>
</tr>


</td>
</tr>
<tr>
<td colspan=2 align=center>
<br>
<input type=submit value=\"Upload Answers\">
</td>
</tr>
</table>

</form>

</blockquote>
[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $return_string
