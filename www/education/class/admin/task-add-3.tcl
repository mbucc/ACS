#
# /www/education/class/admin/task-add-3.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu
#
# this file displays a confirmation page for the user to review the
# information they have just entered.
#

ad_page_variables {
    task_type
    task_name
    {description ""}
    {due_date ""}
    task_id
    {weight ""}
    {grade_id ""}
    {requires_grade_p f}
    {electronic_submission_p f}
    {return_url ""}
}    


set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "Add Tasks"]
set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]


set task_type_plural "[set task_type]s"

set file_id [database_to_tcl_string $db "select fs_file_id_seq.nextval from dual"]

set version_id [database_to_tcl_string $db "select fs_version_id_seq.nextval from dual"]

set parent_id [database_to_tcl_string $db "select [set task_type_plural]_folder_id from edu_classes where class_id = $class_id"]

set return_url "task-add-4.tcl?[export_url_vars file_id task_id]"

set file_title "$task_name"

# make this a general link to task-info.tcl?
if {[string compare $task_type project] == 0} {
    set link "project-info.tcl?project_id=$task_id"
} else {
    set link "${task_type}-info.tcl?${task_type}_id=$task_id"
}

if {![empty_string_p $grade_id]} {
    set grade_insert "grade_id, "
    set grade_value "$grade_id,"
} else {
    set grade_insert ""
    set grade_value ""
}

if {[database_to_tcl_string $db "select count(task_id) from edu_student_tasks where task_id = $task_id"] == 0} {
    

    if {![empty_string_p $grade_id]} {
	set grade_insert "grade_id, "
	set grade_value "$grade_id,"
    } else {
	set grade_insert ""
	set grade_value ""
    }

   ns_db dml $db "insert into edu_student_tasks (
               task_id,
               class_id,
               assigned_by,
               task_type,
               task_name,
               description,
               date_assigned,
               last_modified,
               due_date,
               weight,
               $grade_insert
               online_p,
               file_id,
               requires_grade_p)
           values (
               $task_id,
               $class_id,
               $user_id,
               '$task_type',
               [ns_dbquotevalue $task_name],
               [ns_dbquotevalue $description],
               sysdate,
               sysdate,
               '$due_date',
               '$weight',
               $grade_value
               '$electronic_submission_p',
               NULL,
               '$requires_grade_p')"

}


set return_string "
[ad_header "[capitalize $task_type] Added"]

<h2>[capitalize $task_type] Added</h2>

[ad_context_bar_ws_or_index [list "../one.tcl" "$class_name Home"] [list "" "Administration"] "[capitalize $task_type] Added"]

<hr>

You can now attach a file to the $task_type. Or <a
href=\"\">return to the index page</a>.  This file can be a
document, a photograph, or anything else on your computer.

<form enctype=multipart/form-data method=POST action=\"upload-new.tcl\">
[export_form_vars task_id task_type file_id version_id file_title return_url parent_id return_url]
<blockquote>
<table>
[edu_file_upload_widget $db $class_id $task_type_plural "" [edu_get_ta_role_string]]
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










