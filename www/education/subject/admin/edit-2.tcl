#
# /www/education/subject/admin/edit-2.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu
#
# this is a confirmation page to allow the user to review their proposed
# changes to the subject properties
#

ad_page_variables {
    subject_name
    subject_id
    {description ""}
    {credit_hours ""}
    {prerequisites ""}
    {professors_in_charge ""}
}


# check and make sure we received all of the input we were supposed to

set exception_text ""
set exception_count 0

if {[empty_string_p $subject_name]} {
    append exception_text "<li> You must provide a name for the new subject."
    incr exception_count
}

if {[empty_string_p $subject_id]} {
    append exception_text "<li> You must provide the subject you wish to edit."
    incr exception_count
}


if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}


set db [ns_db gethandle]

# set the user_id

set user_id [edu_subject_admin_security_check $db $subject_id]



ns_db releasehandle $db

ns_return 200 text/html "

[ad_header "Subject Administration - Edit"]

<h2>Confirm Subject Information</h2>

[ad_context_bar_ws [list "../" "Subjects"] [list "index.tcl?subject_id=$subject_id" "$subject_name Administration"] "Edit Subject"]

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
[address_book_display_as_html $description]
</td>
</tr>

<tr>
<th align=left valign=top>
Credit Hours:
</td>
<td>
$credit_hours
</td>
</tr>

<tr>
<th align=left valign=top>
Prerequisites:
</td>
<td>
[address_book_display_as_html $prerequisites]
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
<td align=center valign=top colspan=2>

<form method=post action=\"edit-3.tcl\">
[export_form_vars subject_name subject_id description credit_hours prerequisites professors_in_charge]

<br>
<input type=submit value=\"Edit Subject\">
</form>

</td>
</tr>

</table>

</blockquote>
[ad_footer]
"









