#
# /www/education/class/admin/section-add-edit-2.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page allows a user to add information about a section
# (e.g. a recitation or tutorial)
#

ad_page_variables {
    {instructor_id ""}
    {instructor_name ""}
    {section_id ""}
    section_name
    section_time
    section_place
}

# if this is a section-add then we need to have an instructor_id 
#     and instructor_name
# if this is a section-edit then we need to have a section_id


set db [ns_db gethandle]

# gets the class_id.  If the user is not an admin of the class, it
# displays the appropriate error message and returns so that this code
# does not have to check the class_id to make sure it is valid

set id_list [edu_group_security_check $db edu_class "Manage Users"]
set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]


set exception_count 0
set exception_text ""


if {![empty_string_p $section_id]} {
    # this is an Edit
    set prefix Edit
    set instructor_text ""
} elseif {![empty_string_p $instructor_id] && ![empty_string_p $instructor_name]} {
    # this is an ADD

    set instructor_text "
    <tr>
    <th valign=top align=right>
    Instructor:
    </td>
    <td>
    $instructor_name
    </td>
    </tr>
    "
    set section_id [database_to_tcl_string $db "select user_group_sequence.nextval from dual"]
    set prefix Add
} else {
    append exception_text "<li>You must provide either a section id or a instructor id and an instructor name."
    incr exception_count
}


if {[empty_string_p $section_name]} {
    incr exception_count
    append exception_text "<li>You must include a name for your section."
}


if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}



set return_string "
[ad_header "$class_name @ [ad_system_name]"]

<h2>Confirm Section Information</h3>

[ad_context_bar_ws_or_index [list "../one.tcl" "$class_name Home"] [list "" "Administration"] "$prefix a Section"]

<hr>
<blockquote>

<form method=post action=\"section-add-edit-3.tcl\">
[export_form_vars instructor_id section_id section_name section_place section_time]
<table>

$instructor_text

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
Section Location:
</td>
<td>
$section_place
</td>
</tr>

<tr>
<th align=right>
Section Time:
</td>
<td>
$section_time
</td>
</tr>

<tr>
<td></td>
<td >
<Br>
<input type=submit value=\"$prefix Section\">
</td>
</tr>

</table>

</form>

</blockquote>

[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $return_string

