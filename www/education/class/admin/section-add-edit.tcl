#
# /www/education/class/admin/section-add-edit.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page allows a user to add information about a section
# (e.g. a recitation or tutorial)
#

ad_page_variables {
    {instructor_id ""}
    {section_id ""}
}

# if this is a section-add then we need to have an instructor_id
# if this is a section-edit then we need to have a section_id


set db [ns_db gethandle]

# gets the class_id.  If the user is not an admin of the class, it
# displays the appropriate error message and returns so that this code
# does not have to check the class_id to make sure it is valid

set id_list [edu_group_security_check $db edu_class "Manage Users"]
set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]



if {![empty_string_p $section_id]} {
    # This is an EDIT
    set selection [ns_db 0or1row $db "select section_name, 
                          section_time,
                          section_place
                     from edu_sections
                    where class_id = $class_id
                      and section_id = $section_id"]

    if {$selection == ""} {
	ad_return_complaint 1 "<li>The section you have requested does not belong to this class."
	return
    } else {
	set_variables_after_query
	set prefix Edit
	set instructor_text ""
    }
} elseif {![empty_string_p $instructor_id]} {
    # this is an ADD

    # we need the distinct because it may return multiple roles otherwise (because
    # of user_group_map)
    set instructor_name [database_to_tcl_string_or_null $db "select distinct first_names || ' ' || last_name from users, user_group_map map where users.user_id = $instructor_id and map.user_id = users.user_id and map.group_id = $class_id"]
    if {[empty_string_p $instructor_name] } {
	ad_return_complaint 1 "<li>The user you have provided does not belong to this class."
	return
    }

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
    
    set section_place ""
    set section_time ""
    set section_name ""
    set prefix Add

} else {
    ad_return_complaint 1 "<li> You must include either a section id or an instructor id to have a section."
    return
}



set return_string "
[ad_header "$class_name @ [ad_system_name]"]

<h2>$prefix a Section</h2>

[ad_context_bar_ws_or_index [list "../one.tcl" "$class_name Home"] [list "" "Administration"] "$prefix a Section"]

<hr>
<blockquote>

<form method=post action=\"section-add-edit-2.tcl\">
[export_form_vars instructor_id section_id instructor_name]
<table>

$instructor_text

<tr>
<th align=right>
Section Name:
</td>
<td>
<input type=text maxsize=100 size=25 name=\"section_name\" value=\"[philg_quote_double_quotes $section_name]\">
</td>
</tr>

<tr>
<th align=right>
Section Location:
</td>
<td>
<input type=text maxsize=100 size=15 name=\"section_place\" value=\"[philg_quote_double_quotes $section_place]\">
</td>
</tr>

<tr>
<th align=right>
Section Time:
</td>
<td>
<input type=text maxsize=100 size=15 name=\"section_time\" value=\"[philg_quote_double_quotes $section_time]\">
</td>
</tr>

<tr>
<td></td>
<td >
<Br>
<input type=submit value=\"Continue\">
</td>
</tr>

</table>

</form>

</blockquote>

[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $return_string
