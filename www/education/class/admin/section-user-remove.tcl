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

if {[empty_string_p $student_id] && [empty_string_p $leader_id]} {
    incr exception_count
    append exception_text "<li>You must include the student to be added to the section."
} elseif {[empty_string_p $student_id]} {
    set user_id $leader_id
    set phrase Leader
} else {
    set user_id $student_id
    set phrase Student
}

if {$exception_count == 0} {

    # if the user is not a member of this section, lets just bounce back to the
    # section information page

    set selection [ns_db 0or1row $db "select section_name,
             section_place,
             section_time,
             first_names || ' ' || last_name as student_name
        from users, 
             edu_sections, 
             (select distinct user_id from user_group_map where group_id = $section_id) section_members
       where users.user_id = $user_id
         and section_members.user_id = users.user_id
         and edu_sections.section_id = $section_id
         and edu_sections.class_id = $class_id
    group by section_name, first_names, last_name, section_place, section_time"]

    if {$selection == ""} {
	ad_returnredirect "section-info.tcl?section_id=$section_id"
	return
    } else {
	set_variables_after_query
    }
}


if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}

set group_id $section_id

set return_url "section-info.tcl?section_id=$section_id"

set return_string "
[ad_header "Sections for $class_name @ [ad_system_name]"]
<h2>Remove $phrase from Section</h2>

[ad_context_bar_ws_or_index [list "../one.tcl" "$class_name Home"] [list "" Administration] [list "section-info.tcl?section_id=$section_id" "One Section"] "Remove $phrase"]

<hr>

<blockquote>

<form method=post action=\"group-user-remove.tcl\">
[export_form_vars group_id user_id return_url]

<table>

<tr>
<td colspan=2 align=left>
Are you sure you wish to remove <u>$student_name</u> from this section?
<br><br>
</td>
</tr>

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
Section Time
</td>
<td>
$section_time
</td>
</tr>

<tr>
<th align=right>
Section Location
</td>
<td>
$section_place
</td>
</tr>

<tr>
<td colspan=2 align=center>
<br>
<input type=submit value=\"Remove $phrase\">
<td>
</tr>

</table>

</blockquote>

[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $return_string







