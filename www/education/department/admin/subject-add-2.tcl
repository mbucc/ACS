#
# /www/education/department/admin/subject-add-2.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this allows an admin to add a subject to the department
#

ad_page_variables {
    subject_name
    {description ""}
    {credit_hours ""}
    {prerequisites ""}
    {professors_in_charge ""}
    {subject_number ""}
    {grad_p f}
}


if {[empty_string_p $subject_name]} {
    ad_return_complaint 1 "<li>You must provide a name for the new subject."
    return
}


set db [ns_db gethandle]

# set the user and group information
set id_list [edu_group_security_check $db edu_department]
set user_id [lindex $id_list 0]
set department_id [lindex $id_list 1]
set department_name [lindex $id_list 2]


# so we don't get hit by duplicates if the user double-submits,
# let's generate the subject_id here

set subject_id [database_to_tcl_string $db "select edu_subject_id_sequence.nextval from dual"]


ns_db releasehandle $db

ns_return 200 text/html "

[ad_header "Add a Subject"]
<h2>Confirm Subject Information</h2>

[ad_context_bar_ws [list "../" "Departments"] [list "" "$department_name"] "Add a Subject"]

<hr>
<blockquote>

<table>

<tr>
<th align=left valign=top>
Subject Name:
</td>
<td>
$subject_name
</td>
</tr>

<tr>
<th align=left valign=top>
Description:
</td>
<td>
[edu_maybe_display_text [address_book_display_as_html $description]]
</td>
</tr>

<tr>
<th align=left valign=top>
Credit Hours:
</td>
<td>
[edu_maybe_display_text $credit_hours]
</td>
</tr>

<tr>
<th align=left valign=top>
Prerequisites:
</td>
<td>
[edu_maybe_display_text [address_book_display_as_html $prerequisites]]
</td>
</tr>

<tr>
<th align=left valign=top>
Professors in Charge:
</td>
<td>
[edu_maybe_display_text $professors_in_charge]
</td>
</tr>

<tr>
<th align=left valign=top>
Subject Number:
</td>
<td>
[edu_maybe_display_text $subject_number]
</td>
</tr>

<tr>
<td align=left valign=top>
<b>Is this a Graduate Class?</b>
</td>
<td align=left>
[util_PrettyBoolean $grad_p]
</td>
</tr>

<tr>
<th align=center valign=top colspan=2>

<form method=post action=subject-add-3.tcl>

[export_form_vars subject_name description credit_hours prerequisites professors_in_charge subject_number grad_p subject_id]

<br>
<input type=submit value=\"Create Subject\">
</form>

</td>
</tr>

</table>

</blockquote>
[ad_footer]
"









