#
# /www/education/subject/admin/department-add.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 200
#
# this page allows the user to add more departments to the given subject
#

# expecting subject_id, and sparse arrays of grad_p_${department_id}
# and department_id_${department_id} and subject_name

set_the_usual_form_variables 

# expecting  subject_id, subject_name
# and a list of department_ids with values that are the subject name
# (that is, the text boxes name on the form is the department id and it is the
#  text box for the subject_name)

set db [ns_db gethandle]

# lets make sure it received both the subject_id and the subject_name
set user_id [edu_subject_admin_security_check $db $subject_id]


set exception_text ""
set exception_count 0

if {![info exists subject_id] || [empty_string_p $subject_id]} {
    incr exception_count
    append exception_text "<li> You must provide a subject identification number."
}

if {![info exists subject_name] || [empty_string_p $subject_name]} {
    incr exception_count
    append exception_text "<li> You must provide a subject name."
}


if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}


# lets loop through and get a list of department_id's that now have subject_names
# we just grab all department_ids instead of doing the same query as the previous
# page because there is only a small number of departments so it is quicker to
# loop through them then to join 3 tables in a big select.

set department_ids [database_to_tcl_list_list $db "select department_id, department_name from edu_departments order by lower(department_name)"]

set department_list [list]

foreach department_info $department_ids {
    set department_id [lindex $department_info 0]
    set department_name [lindex $department_info 1]
    if {[info exists department_id_${department_id}] && ![empty_string_p [set department_id_${department_id}]]} {
	
	# here we make a list to pass to the next page.  This consists of,
	# in order, the department_id, subject_number, department_name, and
	# grad_p for the subject

	lappend department_list [list $department_id "[set department_id_${department_id}]" "$department_name" [set grad_p_${department_id}]]
    }
}


# if they did not select anything then redirect them back to the subject page

if {[llength $department_list] == 0} {
    ad_returnredirect "index.tcl?subject_id=$subject_id"
    return
}


set return_string "
[ad_header "[ad_system_name] Administration - Subjects"]

<h2>Add $subject_name to a Department</h2>

[ad_context_bar_ws [list "../" "Subjects"] [list "index.tcl?subject_id=$subject_id" "$subject_name Administration"] "Edit Subject"]

<hr>
<blockquote>

<form method=post action=\"department-add-3.tcl\">

[export_form_vars department_list subject_id]

Are you sure you wish to add $subject_name to the following departments?
<ul>
"

foreach department $department_list {
    append return_string "
    <li>[lindex $department 2]
    <ul>
    <li>Subject Number: [lindex $department 1] 
    <li>Grad? [util_PrettyBoolean [lindex $department 3]]
    </ul>
    "

}

append return_string "
</ul>
<br>
<input type=submit value=\"Add Department\">
</form>
</blockquote>
[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $return_string









