#
# /www/education/subject/admin/class-add.tcl
#
# by randyg@arsdigita.com, aileen@arsdigita.com
#
# this page gives the user a form to fill out class information
#

ad_page_variables {
    subject_id
    user_id
    {term_id ""}
}


set list_to_check [list [list user_id "an instructor"] [list subject_id "a subject"]]

set exception_count 0
set exception_text ""

foreach item $list_to_check {
    if {[empty_string_p [lindex $item 0]]} {
	append exception_text "<li>You must specify [lindex $item 1]\n"
	incr exception_count
    }
}

if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}

set instructor_id $user_id

if {![info exists term_id]} {
    set term_id ""
}


set db [ns_db gethandle]

set user_id [edu_subject_admin_security_check $db $subject_id]

set subject_name [database_to_tcl_string $db "select subject_name from edu_subjects where subject_id = $subject_id"]


set instructor_name [database_to_tcl_string $db "select first_names || ' ' || last_name from users where user_id = $user_id"] 

set term_select_string [edu_term_select_widget $db term_id $term_id]
set date_widget_string [ad_dateentrywidget end_date [database_to_tcl_string $db "select add_months(sysdate,12) from dual"]]

ns_db releasehandle $db

ns_return 200 text/html "
[ad_header "Add a Class @ [ad_system_name]"]

<h2>Add a $subject_name Class</h2>

[ad_context_bar_ws [list "/subject/" "Subjects"] [list "" "Subject Administration"] "Add a Class"]

<hr>
<blockquote>

<form method=post action=\"class-add-2.tcl\">
[export_form_vars instructor_id subject_id]

<table>
<tr><th align=right>Instructor
<td>$instructor_name
</tr>

<tr><th align=right>Class Title
<td><input type=text size=60 name=group_name maxsize=100 value=\"$subject_name\"> 
</tr>

<tr><th align=right>Term: 
<td>
$term_select_string
</tr>

<tr><th valign=top align=right>Meeting time and place: 
<br>(e.g. Lecture: TR10 (10-250) Recitation: WF10 (13-4101) or WF11 (13-4101))</th>
<td>[edu_textarea where_and_when]</td>
</tr>

<tr><th align=right>Date to Start Displaying Class Web Page: 
<td>[ad_dateentrywidget start_date]
</tr>

<tr><th align=right>Date to Stop Displaying Class Web Page: 
<td>$date_widget_string
</tr>

<tr><th align=right>Will the class web page and documents be open to the public?
<td><input type=radio name=public_p checked value=t>Yes &nbsp;<input type=radio name=public_p value=f>No
</tr>

<tr><th align=right>Do students recieve grades?
<td><input type=radio name=grades_p value=t checked>Yes &nbsp;<input type=radio name=grades_p value=f>No
</tr>

<tr><th align=right>Will the class have teams?
<td><input type=radio name=teams_p value=t>Yes &nbsp;<input type=radio name=teams_p value=f checked>No
</tr>

<tr><th align=right>Will the class have exams?
<td><input type=radio name=exams_p value=t checked>Yes &nbsp;<input type=radio name=exams_p value=f>No
</tr>

<tr><th align=right>Will the class have a final exam?
<td><input type=radio name=final_exam_p value=t checked>Yes &nbsp;<input type=radio name=final_exam_p value=f>No
</tr>
<tr><th align=right>Class Description
<td><textarea wrap name=description rows=4 cols=50></textarea>
</tr>

<tr><td colspan=2 align=center><input type=submit value=\"Continue\"></td>
</tr>
</table>
</form>

</blockquote>
[ad_footer]
"





