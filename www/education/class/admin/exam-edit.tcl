#
# /www/education/class/admin/exam-edit.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, February 2000
#
#
# this page is where teachers can go to issue exams.
# basically, they are able to upload a file/url into the file storage
# system and then associate a due date with it.
#

ad_page_variables {
    exam_id
    {return_url ""}
}


set db [ns_db gethandle]

# gets the class_id.  If the user is not an admin of the class, it
# displays the appropriate error message and returns so that this code
# does not have to check the class_id to make sure it is valid

set id_list [edu_group_security_check $db edu_class "Edit Tasks"]
set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]


if {[empty_string_p $exam_id]} {
    ad_return_complaint 1 "<li>You must include an exam to edit."
    return
}

set selection [ns_db 0or1row $db "select class_id as exam_class_id,
                            first_names as teacher_first_name,
                            last_name as teacher_last_name,
                            exam_name,
                            comments,
                            e.creation_date,
                            last_modified,
                            date_administered,
                            e.file_id,
                            weight,
                            grade_id,
                            online_p,
                            version_id
                       from edu_exams e, 
                            users,
                            fs_versions_latest
                      where exam_id = $exam_id
                        and class_id = $class_id
                        and e.file_id = fs_versions_latest.file_id(+) 
                        and e.teacher_id = users.user_id"]

if { $selection == "" } {
    ad_return_complaint 1 "<li> The exam id you have provided does not exist.  Please check your identification number and try again."
    return
} else {
    set_variables_after_query
}

set new_version_id [database_to_tcl_string $db "select fs_version_id_seq.nextval from dual"]


set return_string "
[ad_header "Edit Exam @ [ad_system_name]"]

<h2>Edit Exam</h2>

[ad_context_bar_ws_or_index [list "../one.tcl" "$class_name Home"] [list "" "Administration"] "Edit Exam"]

<hr>

This exam was created by 
$teacher_first_name $teacher_last_name on 
[util_AnsiDatetoPrettyDate $creation_date].  It was last 
updated on [util_AnsiDatetoPrettyDate $last_modified].<br><br>

<blockquote>

<form enctype=multipart/form-data method=POST action=\"exam-edit-2.tcl\">
[export_form_vars return_url file_id exam_id new_version_id]

<table>
<tr>
<th valign=top align=right> Exam Name: </td>
<td valign=top>
<input type=text size=30 maxsize=100 name=exam_name value=\"[philg_quote_double_quotes $exam_name]\">
</td>
</tr>

<tr>
<th valign=top align=right> Comments: </td>
<td valign=top>
[edu_textarea comments $comments 40 4]
</td>
</tr>

<tr>
<th valign=top align=right> Exam Date: </td>
<td valign=top>
[ad_dateentrywidget date_administered [database_to_tcl_string $db "select sysdate + 14 from dual"]]
</td>
</tr>

<tr>
<th valign=top align=right> Fraction of Exam Grade: </td>
<td valign=top>
<input type=text size=5 maxsize=10 name=weight value=\"$weight\">\%
</font>
</td>
</tr>
<tr>
<th valign=top align=right>Grade Policy Group</th>
<td valign=top>
<select name=grade_id>
<option value=\"\">None
"

set selection [ns_db select $db "select grade_name, weight, grade_id as select_grade_id from edu_grades where class_id=$class_id order by grade_name"]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    
    append return_string "
    <option value=$select_grade_id"
    
    if {$grade_id==$select_grade_id} {
	append return_string " selected"
    }
    append return_string "
    >$grade_name - $weight\%"
}

append return_string "
</select>
</td>
</tr>

<tr>
<th valign=top align=right> 
Administered online?
</td>
<td valign=top>
"

if {[string compare $online_p t] == 0} {
    append return_string "
    <input type=radio name=online_p checked value=t> Yes
    <input type=radio name=online_p value=f> No
    "
} else {
    append return_string "
    <input type=radio name=online_p value=t> Yes
    <input type=radio name=online_p checked value=f> No
    "
}

append return_string "
<tr>
<td colspan=2 align=center>
<br>
<input type=submit value=\"Edit Exam\">
</td>
</tr>
</table>

</form>

</blockquote>
[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $return_string

