#
# /www/education/subject/admin/class-add-2.tcl
#
# by randyg@arsdigita.com, aileen@arsdigita.com, January 2000
#
# this is the confirmation page for the addition of a subject.
#

ad_page_variables {
    group_name
    term_id
    {where_and_when ""}
    {ColValue.start%5fdate.day ""}
    {ColValue.start%5fdate.month ""}
    {ColValue.start%5fdate.year ""}
    {ColValue.end%5fdate.day ""} 
    {ColValue.end%5fdate.month ""}
    {ColValue.end%5fdate.year ""}
    {public_p t}
    {grades_p t}
    {exams_p t}
    {final_exam_p t}
    {description ""}
    subject_id
    instructor_id
    {teams_p f}
}



set db [ns_db gethandle]

set user_id [edu_subject_admin_security_check $db $subject_id]


#check the input
set exception_count 0
set exception_text ""


if {[empty_string_p $subject_id]} {
    incr exception_count 
    append exception_text "<li>You must include the subject identifiaction number."
}

if {[empty_string_p $group_name]} {
    incr exception_count 
    append exception_text "<li>You must name your class."
}

if {[empty_string_p $term_id]} {
    incr exception_count
    append exception_text "<li>You must choose a term."
}

# put together due_date, and do error checking

set form [ns_getform]

# ns_dbformvalue $form start_date date start_date will give an error
# message if the day of the month is 08 or 09 (this octal number problem
# we've had in other places).  So I'll have to trim the leading zeros
# from ColValue.start%5fdate.day and stick the new value into the $form
# ns_set.

set "ColValue.start%5fdate.day" [string trimleft [set ColValue.start%5fdate.day] "0"]
ns_set update $form "ColValue.start%5fdate.day" [set ColValue.start%5fdate.day]

if [catch  { ns_dbformvalue $form start_date date start_date} errmsg ] {
    incr exception_count
    append exception_text "<li>The date was specified in the wrong format.  The date should be in the format Month DD YYYY.\n"
} elseif { [string length [set ColValue.start%5fdate.year]] != 4 } {
    incr exception_count
    append exception_text "<li>The year needs to contain 4 digits.\n"
} elseif {[database_to_tcl_string $db "select round(sysdate) - to_date('$start_date','YYYY-MM-DD') from dual"] > 1} {
    incr exception_count
    append exception_text "<li>The start date must be in the future."
}


set "ColValue.end%5fdate.day" [string trimleft [set ColValue.end%5fdate.day] "0"]
ns_set update $form "ColValue.end%5fdate.day" [set ColValue.end%5fdate.day]

if [catch  { ns_dbformvalue $form end_date date end_date} errmsg ] {
    incr exception_count
    append exception_text "<li>The date was specified in the wrong format.  The date should be in the format Month DD YYYY.\n"
} elseif { [string length [set ColValue.end%5fdate.year]] != 4 } {
    incr exception_count
    append exception_text "<li>The year needs to contain 4 digits.\n"
} elseif {[database_to_tcl_string $db "select round(sysdate) - to_date('$end_date','YYYY-MM-DD') from dual"] > 1} {
    incr exception_count
    append exception_text "<li>The end date must be in the future."
}

if {[string compare $exception_count 0] == 0 && ![empty_string_p $start_date] && ![empty_string_p $end_date]} {
    if {[database_to_tcl_string $db "select to_date('$end_date', 'YYYY-MM-DD') - to_date('$start_date', 'YYYY-MM-DD') from dual"] < 0 } {
	incr exception_count
	append exception_text "<li>The end date must be after the start day."
    }
}


if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}


# now that we know we have valid input, we display the confirmation page

set instructor_name [database_to_tcl_string $db "select first_names || ' ' last_name from users where user_id=$instructor_id"]

set group_id [database_to_tcl_string $db "select user_group_sequence.nextval from dual"]

set subject_name [database_to_tcl_string $db "select subject_name from edu_subjects where subject_id = $subject_id"]
set term_string [database_to_tcl_string $db "select term_name from edu_terms where term_id = $term_id"]

ns_db releasehandle $db

set return_string "
[ad_header "Add a Class @ [ad_system_name]"]

<h2>Add a $subject_name Class</h2>

[ad_context_bar_ws [list "../" "Subjects"] [list "" "Subject Administration"] "Add a Class"]



<hr>
<blockquote>
<table>
<tr><th align=right>Instructor:
</td>
<td>$instructor_name
</tr>

<tr><th align=right>Class Title:
</td>
<td>$group_name
</tr>

<tr><th align=right>Term: 
</td>
<td>
$term_string
</tr>

<tr><th valign=top align=right>Meeting time and place: </th>
<td>$where_and_when</td>
</tr>

<tr><th align=right>Date to Start Displaying<br>Class Web Page: 
<td valign=top>[util_AnsiDatetoPrettyDate $start_date]
</td>
</tr>

<tr><th align=right>Date to Stop Displaying<br>Class Web Page: 
<td valign=top>[util_AnsiDatetoPrettyDate $end_date]
</td>
</tr>

<tr><th align=right>Will the class web page and<br>documents be open to the public?
<td valign=top>[util_PrettyBoolean $public_p]
</td>
</tr>

<tr><th align=right>Do students recieve grades?
<td valign=top>[util_PrettyBoolean $grades_p]
</td>
</tr>

<tr><th align=right>Will the class have teams?
<td valign=top>[util_PrettyBoolean $teams_p]
</td>
</tr>

<tr><th align=right>Will the class have exams?
<td valign=top>[util_PrettyBoolean $exams_p]
</td>
</tr>

<tr><th align=right>Will the class have a final exam?
<td valign=top>[util_PrettyBoolean $final_exam_p]
</td>
</tr>
<tr><th align=right>Class Description
</td>
"

if {[empty_string_p $description]} {
    append return_string "<td valign=top>None"
} else {
    append return_string "<td valign=top>$description"
}

append return_string "
</td>
</tr>

<tr>
<td colspan=2 align=center>
<br>
<form method=post action=\"class-add-3.tcl\">
[export_form_vars group_name term_id where_and_when start_date end_date public_p grades_p exams_p final_exam_p description subject_id instructor_id teams_p group_id]

<input type=submit value=\"Create a New Class\"></td>

</form>
</td>
</tr>
</table>



</blockquote>
[ad_footer]
"

ns_return 200 text/html $return_string







