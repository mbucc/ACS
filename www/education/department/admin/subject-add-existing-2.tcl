#
# /www/education/department/admin/subject-add-existing-2.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page allows the admin to add an existing subject to the department
#

ad_page_variables {
    subject_id
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


# lets make sure that the subject_id provided does not map to the department

if {[database_to_tcl_string $db "select count(department_id) from edu_subject_department_map where subject_id = $subject_id and department_id = $department_id"] > 0} {
    ad_return_complaint 1 "<li> The subject you are trying to add already exists in this department."
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

Please provide a subject number and graduate status for $subject_name.  Examples of subject nubmers include CS101 and 6.001.

<form method=post action=\"subject-add-existing-3.tcl\">
<b>Subject Number:</b> [ad_space] <input type=text size=15 maxsize=20 name=subject_number>
[export_form_vars subject_id]
<p>

<b>Is this a Graduate Class?</b> [ad_space] 

<input type=radio name=grad_p value=t> Yes
<input type=radio name=grad_p value=f checked> No

<p>
<input type=submit value=\"Continue\">
</form>


</blockquote>
[ad_footer]
"














