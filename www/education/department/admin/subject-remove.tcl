#
# /www/education/department/subject-remove.tcl
#
# by randyg@arsdigita, aileen@mit.edu, January 2000
#
# this page confirms that the user wants to remove
# a subject form the deparement/subject mapping table
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
set department_id [lindex $id_list 1]
set department_name [lindex $id_list 2]


# lets make sure that the subject_id provided maps to the department

if {[database_to_tcl_string $db "select count(department_id) from edu_subject_department_map where subject_id = $subject_id and department_id = $department_id"] == 0} {
    ad_return_complaint 1 "<li> The subject you are trying to delete does not belong to the department $department_name."
    return
}


set subject_name [database_to_tcl_string $db "select subject_name from edu_subjects where subject_id = $subject_id"]

ns_db releasehandle $db

ns_return 200 text/html "

[ad_header "Department Administration @ [ad_system_name]"]

<h2>Remove $subject_name</h2>

[ad_context_bar_ws [list "../" "Departments"] [list "" "$department_name Administration"] "Remove Subject"]

<hr>
<blockquote>

Are you sure you want to remove $subject_name from the department of $department_name?  

<form method=post action=\"subject-remove-2.tcl\">
[export_form_vars subject_id]
<input type=submit name=button value=\"Remove Subject\">
</form>

</blockquote>
[ad_footer]
"




