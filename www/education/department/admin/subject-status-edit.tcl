#
# /www/education/department/admin/subject-status-edit.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page allows the admin to change the subject number and 
# graduate status of the class
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


set selection [ns_db 0or1row $db "select subject_name, 
              subject_number, 
              grad_p 
         from edu_subjects sub, 
              edu_subject_department_map map 
        where sub.subject_id = map.subject_id 
          and map.department_id = $department_id 
          and sub.subject_id = $subject_id"]

if { $selection == "" } {
    # the department is not mapped to this subject
    ad_return_complaint 1 "<li>The subject you have requested does not belong to this department."
    return
} else {
    set_variables_after_query
}


set return_string "

[ad_header "Edit an Existing Subject @ [ad_system_name]"]
<h2>Edit Subject Number</h2>

[ad_context_bar_ws [list "../" "Departments"] [list "" "$department_name Administration"] "Edit Subject Properties"]


<hr>
<blockquote>
<form method=post action=\"subject-status-edit-2.tcl\">

<b>Subject Name:</b> [ad_space 1] $subject_name

<p>

<b>Subject Number:</b> [ad_space 1] <input type=text size=15 maxsize=20 value=\"$subject_number\" name=subject_number>

<br><br>

<b>Is this a Graduate Class?</b> [ad_space 1]
"

if {[string compare $grad_p t] == 0} {
    append return_string "
    <input type=radio name=grad_p value=t checked> Yes
    <input type=radio name=grad_p value=f> No
    "
} else {
    append return_string "
    <input type=radio name=grad_p value=t> Yes
    <input type=radio name=grad_p value=f checked> No
    "
}

append return_string "
[export_form_vars subject_id]
<p>
<input type=submit value=\"Continue\">
</form>

</blockquote>
[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $return_string













