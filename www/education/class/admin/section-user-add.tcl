#
# /www/education/class/admin/section-user-add.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, February 2000
#
# this page allows the user to add a student to the section
#

ad_page_variables {
    section_id
    {student_id ""}
    {instructor_id ""}
}


# either student_id or instructor_id must be not null


set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "Manage Users"]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]


set exception_count 0
set exception_text ""

if {[empty_string_p $section_id]} {
    incr exception_count
    append exception_text "<li>You must provide a section number."
}

if {[empty_string_p $student_id] && [empty_string_p $instructor_id]} {
    incr exception_count
    append exception_text "<li>You must include the user to be added to the section."
} else {
    if {![info exists student_id] || [empty_string_p $student_id]} {
	set phrase Leader
	set member_sql_check "and not role = '[edu_get_student_role_string]'"
	set user_id $instructor_id
	set error_phrase "must be a TA or a professor to be a leader of this section."
	set role administrator
    } else {
	set phrase Student
	set member_sql_check ""
	set error_phrase "is already a member of this section."
	set user_id $student_id
	set role member
    }
}


if {$exception_count == 0} {

    set selection [ns_db 0or1row $db "select section_name,
             section_place,
             section_time,
             first_names || ' ' || last_name as student_name
        from users,
             edu_sections
       where user_id = $user_id
         and section_id = $section_id
         and class_id = $class_id
    group by section_name, first_names, last_name, section_place, section_time"]


    if {$selection == ""} {
	incr exception_count
	append exception_text "<li>The section number that you have provided is not a section in this class."
    } else {
	set_variables_after_query

	set member_p [database_to_tcl_string $db "select count(distinct group_id) from user_group_map where group_id = $section_id and user_id = $user_id $member_sql_check"]

	if {$member_p != 0} {
	    incr exception_count
	    append exception_text "<li>$student_name $error_phrase"
	}
    }
}


if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}

set group_id $section_id

set return_url "section-info.tcl?section_id=$section_id"

set return_string "
[ad_header "View Sections for $class_name @ [ad_system_name]"]
<h2>Add a $phrase to $section_name</h2>

[ad_context_bar_ws_or_index [list "../one.tcl" "$class_name Home"] [list "" Administration] [list "section-info.tcl?section_id=$section_id" "$section_name"] "Add $phrase"]

<hr>

<blockquote>

<form method=post action=\"group-user-add.tcl\">
[export_form_vars group_id user_id return_url role]

Are you sure you wish to add <u>$student_name</u> to this section?

<p>

<table>

<tr>
<tr>
<th align=right>
Section Name:
</td>
<td>
$section_name
</td>
</tr>


<tr>
<th align=right>
Section Place
</td>
<td>
$section_place
</td>
</tr>

<tr>
<th align=right>
Section Time
</td>
<td>
$section_time
</td>
</tr>

<tr>
<td colspan=2 align=center>
<br>
<input type=submit value=\"Add $phrase\">
<td>
</tr>

</table>

</blockquote>

[ad_footer]
"


ns_db releasehandle $db

ns_return 200 text/html $return_string






