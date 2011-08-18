#
# /www/education/subject/admin/department-add.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 200
#
# this page allows the user to add more departments to the given subject
#

ad_page_variables {
    subject_id
}


set db [ns_db gethandle]

set user_id [edu_subject_admin_security_check $db $subject_id]


# lets make sure it received both the subject_id and the subject_name

set exception_text ""
set exception_count 0

if {![info exists subject_id] || [empty_string_p $subject_id]} {
    incr exception_count
    append exception_text "<li> You must provide a subject identification number."
}

set subject_name [database_to_tcl_string_or_null $db "select subject_name from edu_subjects where subject_id = $subject_id"]

if {[empty_string_p $subject_name]} {
    incr exception_count
    append exception_text "<li>The subject you have requested does not exist."
}


if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}



# if the person is a site-wide admin, give them the option to add any 
# department in the system that does not already have the class
# else,
# give the person the option to add this subject to a department if they
# are the admin of the department and the subject is not already in
# the given deparmtment
# else,
# supply an error message

set n_other_departments 0

if { [ad_administrator_p $db $user_id] } {
    set selection [ns_db select $db "select department_name, 
                       department_id 
                  from edu_departments 
                 where department_id not in (select department_id 
                                        from edu_subject_department_map map 
                                       where map.department_id = edu_departments.department_id 
                                         and subject_id = $subject_id)
              order by lower(department_name)"] 

} else {
    # we want to select the departments that the person is a member of 
    set selection [ns_db select $db "select dept.department_id,
                                            dept.department_name
                                from user_group_map map,
                                     edu_departments dept
                               where map.group_id = dept.department_id
                                 and map.user_id = $user_id
                                 and dept.department_id not in (select
                                           sdmap.department_id
                                           from edu_subject_department_map sdmap
                                          where sdmap.subject_id = $subject_id)
                            order by lower(department_name)"]
}

set n_departments 0


set html "

[ad_header "[ad_system_name] Administration - Subjects"]
<h2>Add $subject_name to a Department</h2>

[ad_context_bar_ws [list "../" "Subjects"] [list "index.tcl?subject_id=$subject_id" "$subject_name Administration"] "Edit Subject"]

<hr>
<blockquote>

To add a department, enter in the course number.

<form method=post action=\"department-add-2.tcl\">
<table>
<tr>
<th align=left>Department Name<br><Br></td>
<td valign=top align=center><b>Department<br>Number</b></td>
<td valign=top align=center><b>Is this a Graduate<br>Subject?</b></td>
</tr>
"

while {[ns_db getrow $db $selection]} {
    incr n_departments
    set_variables_after_query

    append html "
    <tr>
    <td align=left>$department_name
    </td>
    <td align=center>
    <input type=text size=10 name=department_id_${department_id} maxsize=20>
    </td>
    <td align=center>
    <input type=radio name=grad_p_${department_id} value=t> Yes
    <input type=radio name=grad_p_${department_id} value=f checked> No
    </td>
    </tr>"

}


if {$n_departments == 0} {
    ad_return_complaint 1 "<li> There are no departments available for this class."
    return
}


ns_db releasehandle $db     

set return_string "
$html
<tr>
<td colspan=2 align=center>
<input type=submit value=\"Continue\">
</td>
</tr>
</table>

[export_form_vars subject_id subject_name]

</form>
</blockquote>
[ad_footer]
"

ns_return 200 text/html $return_string









