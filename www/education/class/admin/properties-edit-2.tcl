# 
# /www/education/class/admin/properties-edit-2.tcl
#
# by randyg@arsdigita.com, aillen@arsdigita.com
#
# This page displays the confirmation page so that the class admin can review
# the changes about to be made
#

ad_page_variables {
    class_name
    {term_id ""}
    {where_and_when ""}
    {ColValue.start%5fdate.month ""}
    {ColValue.start%5fdate.day ""}
    {ColValue.start%5fdate.year ""}
    {ColValue.end%5fdate.month ""}
    {ColValue.end%5fdate.day ""}
    {ColValue.end%5fdate.year ""}
    {public_p t}
    {grades_p t}
    {exams_p t}
    {final_exam_p t}
    {teams_p f}
    {description ""} 
    {pretty_role_ta "Teaching Assistant"}
    {pretty_role_professor Professor}
    {pretty_role_student Student}
    {pretty_role_dropped Dropped}
    {pretty_role_plural_ta "Teaching Assistants"}
    {pretty_role_plural_professor Professors}
    {pretty_role_plural_student Students}
    {pretty_role_plural_dropped Dropped}
}

set db [ns_db gethandle]

# gets the class_id.  If the user is not an admin of the class, it
# displays the appropriate error message and returns so that this code
# does not have to check the class_id to make sure it is valid

set id_list [edu_group_security_check $db edu_class "Edit Class Properties"]
set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]
set old_class_name [lindex $id_list 2]


#check the input
set exception_count 0
set exception_text ""


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

set variables_to_check [list [list class_name "Class Title"] [list grades_p "Grades"] [list exams_p "Exams"] [list final_exam_p "Final Exam"] [list term_id "Term"] [list teams_p Teams]]

foreach var $variables_to_check {
    if {![info exists [lindex $var 0]] || [empty_string_p [set [lindex $var 0]]]} {
	incr exception_count
	append exception_text "<li>You forgot to provide a value for the [lindex $var 1]"
    }
}

if {![info exists description]} {
    incr exception_count
    append exception_text "<li>You must provide a description."
}


if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}


#now that we know we have valid input, we display the confirmation page


set return_string "

[ad_header "Class Administration @ [ad_system_name]"]

<h2>Edit Class Properties for $old_class_name</h2>

[ad_context_bar_ws_or_index [list "../one.tcl" "$old_class_name"] [list "" Administration] "Edit Properties"]


<hr>
<blockquote>
<table>
<form method=post action=\"properties-edit-3.tcl\">

<tr><th align=right>Class Title:
</td>
<td>$class_name
</tr>

<tr><th align=right>Term: 
</td>
<td>
[database_to_tcl_string $db "select term_name from edu_terms where term_id = $term_id"]
</tr>

<tr><th valign=top align=right>When/Where: </th>
<td>$where_and_when</td>
</tr>

<tr><th align=right>Start displaying<br>web page: 
<td valign=top>[util_AnsiDatetoPrettyDate $start_date]
</td>
</tr>

<tr><th align=right>Stop displaying<br>web page: 
<td valign=top>[util_AnsiDatetoPrettyDate $end_date]
</td>
</tr>

<tr><th align=right>Make class documents public:
<td valign=top>[util_PrettyBoolean $public_p]
</td>
</tr>

<tr><th align=right>Grades:
<td valign=top>[util_PrettyBoolean $grades_p]
</td>
</tr>

<tr><th align=right>Student teams:
<td valign=top>[util_PrettyBoolean $teams_p]
</td>
</tr>

<tr><th align=right>Exams:
<td valign=top>[util_PrettyBoolean $exams_p]
</td>
</tr>

<tr><th align=right>Final exam:
<td valign=top>[util_PrettyBoolean $final_exam_p]
</td>

<tr><th align=right valign=top>Class Description
</td>
"

if {[empty_string_p $description]} {
    append return_string "<td valign=top>None"
} else {
    append return_string "<td valign=top>$description"
}

append return_string "
<tr>
<th align=right valign=top>Staff Titles:</th>
<td>

<table>
<tr>
<th>&nbsp</th>
<th align=left>Singular</th>
<th align=left>Plural</th>
</tr>
"

set selection [ns_db select $db "select role, pretty_role, pretty_role_plural from edu_role_pretty_role_map where group_id=$class_id and role != 'administrator' order by sort_key"]


while {[ns_db getrow $db $selection]} {
    set_variables_after_query

    append return_string "
    <tr>
    <th align=left>[capitalize $role]</th>
    <td>
    [set pretty_role_[string tolower [join $role "_"]]]
    </td>
    <td>
    [set pretty_role_plural_[string tolower [join $role "_"]]]
    </td>
    </tr>
    "
}
    

append return_string "
</table>
</td>
</tr>

<tr>
<td colspan=2 align=center>
<br>
[export_form_vars start_date end_date class_name term_id where_and_when public_p grades_p exams_p final_exam_p teams_p description pretty_role_ta pretty_role_professor pretty_role_student pretty_role_dropped pretty_role_plural_ta pretty_role_plural_professor pretty_role_plural_student pretty_role_plural_dropped]

<input type=submit value=\"Edit Class Properties\"></td>

</form>
</td>
</tr>
</table>



</blockquote>
[ad_footer]
"


ns_db releasehandle $db

ns_return 200 text/html $return_string
