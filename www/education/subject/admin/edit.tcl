#
# /www/education/subject/admin/edit.tcl
#
# randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page allows the user to edit the properties of the passed in subject
#

ad_page_variables {
    subject_id
}


if {[empty_string_p $subject_id]} {
    ad_return_complaint 1 "<li>You must include a subject identification number."
    return
}

set db [ns_db gethandle]

set user_id [edu_subject_admin_security_check $db $subject_id]


set selection [ns_db 0or1row $db "select subject_name, description, credit_hours, prerequisites, professors_in_charge from edu_subjects where subject_id = $subject_id"]

if {$selection == ""} {
    ad_return_complaint 1 "<li> The subject you have requested does not exist."
    return
} else {
    set_variables_after_query
}


ns_db releasehandle $db

ns_return 200 text/html "

[ad_header "[ad_system_name] Administration - Add a Subject"]

<h2>Add a Subject</h2>

[ad_context_bar_ws [list "../" "Subjects"] [list "index.tcl?subject_id=$subject_id" "$subject_name Administration"] "Edit Subject"]

<hr>
<blockquote>
<form method=post action=\"edit-2.tcl\">
[export_form_vars subject_id]
<table>

<tr>
<th align=right>Subject Name</th>
<td><input type=text size=40 name=subject_name value=\"$subject_name\"></td>
</tr>

<tr>
<th align=right>Description</th>
<td>[edu_textarea description $description]</td>
</tr>
<tr>
<th align=right>Number of Units</th>
<td><input type=text name=credit_hours size=8 value=\"$credit_hours\"></td>
</tr>

<tr>
<th align=right>Prerequisites</th>
<td>[edu_textarea prerequisites $prerequisites 60 4]</td>
</tr>

<tr>
<th align=right>Professor(s) in Charge</th>
<td><input type=text name=professors_in_charge size=40 maxsize=200 value=\"$professors_in_charge\">
</tr>

[edu_empty_row]
<tr>
<th></th>
<td><input type=submit value=Continue></td>
</tr>

</table>
</form>
</blockquote>

[ad_footer]
"

