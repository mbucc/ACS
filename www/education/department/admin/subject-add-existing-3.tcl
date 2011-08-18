#
# /www/education/department/admin/subject-add-existing-3.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page confirms the information for adding an existing subject
#

ad_page_variables {
    subject_id
    {subject_number ""}
    {grad_p f}
}


if {[empty_string_p $subject_id]} {
    ad_return_complaint 1 "<li>You must include a subject identification number."
    return
}


set db [ns_db gethandle]

# set the user and group information
set id_list [edu_group_security_check $db edu_department]
set user_id [lindex $id_list 0]
set department_id [lindex $id_list 1]
set department_name [lindex $id_list 2]


# lets make sure that the subject_id provided maps to the departments

if {[database_to_tcl_string $db "select count(department_id) from edu_subject_department_map where subject_id = $subject_id and department_id = $department_id"] > 0} {
    ad_return_complaint 1 "<li> The subject you are trying to add already exists in $department_name"
    return
}


set subject_name [database_to_tcl_string $db "select subject_name from edu_subjects where subject_id = $subject_id"]


ns_db releasehandle $db

ns_return 200 text/html "

[ad_header "Add an Existing Subject @ [ad_system_name]"]
<h2>Add an Existing Subject</h2>

[ad_context_bar_ws [list "../" "Departments"] [list "" "$department_name Administration"] "Add a Subject"]


<hr>
<blockquote>

Are you sure you wish to add $subject_name to the department $department_name?

<form method=post action=\"subject-add-existing-4.tcl\">

[export_form_vars subject_id subject_number grad_p]

<b>Subject Name:</b> [ad_space] $subject_name

<p>

<b>Subject Number:</b> [ad_space] [edu_maybe_display_text $subject_number]

<p>

<b>Is this a Graduate Class?</b> [ad_space] [util_PrettyBoolean $grad_p]

<p>

<input type=submit name=button value=\"Add Subject\">
</form>


</blockquote>
[ad_footer]
"














