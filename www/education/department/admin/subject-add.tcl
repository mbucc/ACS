#
# /www/education/department/admin/subject-add.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this allows an admin to add a subject to the department
#


# no arguments are expected

set db [ns_db gethandle]

# set the user and group information
set id_list [edu_group_security_check $db edu_department]
set user_id [lindex $id_list 0]
set department_id [lindex $id_list 1]
set department_name [lindex $id_list 2]


ns_db releasehandle $db

ns_return 200 text/html "

[ad_header "Add a New Subject @ [ad_system_name]"]
<h2>Add a New Subject</h2>

[ad_context_bar_ws [list "../" "Departments"] [list "" "$department_name Administration"] "Add a New Subject"]

<hr>
<blockquote>

<form method=post action=\"subject-add-2.tcl\">

<table>

<tr>
<th align=left>
Subject Name:
</td>
<td>
<input type=text name=subject_name size=40 maxsize=100>
</td>
</tr>

<tr>
<th align=left>
Description:
</td>
<td>
[edu_textarea description]
</td>
</tr>

<tr>
<th align=left>
Credit Hours:
</td>
<td>
<input type=text name=credit_hours size=10 maxsize=50>
</td>
</tr>

<tr>
<th align=left valign=top>
Prerequisites:
</td>
<td>
[edu_textarea prerequisites "" 60 4]
</td>
</tr>

<tr>
<th align=left>
Professor(s) in Charge:
</td>
<td>
<input type=text name=professors_in_charge size=40 maxsize=200>
</td>
</tr>

<tr>
<td align=left>
<b>Subject Number: </b>
</td><td align=left>
<input type=text name=subject_number size=10 maxsize=20>
</td>
</tr>

<tr>
<td align=left colspan=2 valign=top>
<b>Is this a Graduate Class?</b>
<input type=radio name=grad_p value=t> Yes
<input type=radio name=grad_p value=f checked> No
</td>
</tr>

<tr>
<th align=center valign=top colspan=2>
<input type=submit value=Continue>
</td>
</tr>

</table>
</form>

</blockquote>
[ad_footer]
"














