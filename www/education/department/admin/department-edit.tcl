#
# /www/education/department/admin/department-edit.tcl
#
# by randyg@arsdigita.com, aileen@arsdigita.com, January 2000
#
# this page allows the user to edit informaiton about a department
#

# not expecting any variables

set db [ns_db gethandle]

# set the user and group information
set id_list [edu_group_security_check $db edu_department]
set user_id [lindex $id_list 0]
set department_id [lindex $id_list 1]
set department_name [lindex $id_list 2]


set selection [ns_db 0or1row $db "select department_name, 
                         department_number, 
                         external_homepage_url,
                         mailing_address,
                         phone_number,
                         fax_number,
                         inquiry_email,
                         description,
                         mission_statement
                    from edu_departments
                   where department_id = $department_id"]

if {$selection == ""} {
    # this should never, ever happen because of the call to edu_group_security_check
    ad_return_complaint 1 "<li> The group that you are logged in as is not a department.  Please return to <a href=\"/pvt/home.tcl\">your home page</a> and try again."
    return
} else {
    set_variables_after_query
}


if {[empty_string_p $external_homepage_url]} {
    set external_homepage_url "http://"
}

ns_db releasehandle $db

ns_return 200 text/html "
[ad_header "Edit a Department @ [ad_system_name]"]
<h2>Edit Department</h2>

[ad_context_bar_ws [list "../" "Departments"] [list "" "$department_name Administration"] "Edit Department Information"]

<hr>
<blockquote>

<form method=post action=\"department-edit-2.tcl\">

<table>

<tr>
<th align=left valign=top>
Department Name
</td>
<td>
<input type=text name=group_name value=\"$department_name\" size=50 maxsize=100>
</td>
</tr>

<tr>
<th align=left valign=top>
Department Number
</td>
<td>
<input type=text name=department_number value=\"$department_number\" size=20 maxsize=100>
</td>
</tr>

<tr>
<th align=left valign=top>
External Homepage URL
</td>
<td>
<input type=text name=external_homepage_url value=\"$external_homepage_url\" size=40 maxsize=200>
</td>
</tr>

<tr>
<th align=left valign=top>
Mailing Address
</td>
<td>
<input type=text name=mailing_address value=\"$mailing_address\" size=40 maxsize=200>
</td>
</tr>


<tr>
<th align=left valign=top>
Phone Number
</td>
<td>
<input type=text name=phone_number value=\"$phone_number\" size=15 maxsize=20>
</td>
</tr>

<tr>
<th align=left valign=top>
Fax Number
</td>
<td>
<input type=text name=fax_number value=\"$fax_number\" size=15 maxsize=20>
</td>
</tr>

<tr>
<th align=left valign=top>
Inquiry Email Address
</td>
<td>
<input type=text name=inquiry_email value=\"$inquiry_email\" size=25 maxsize=50>
</td>
</tr>


<tr>
<th align=left valign=top>
Description
</td>
<td>
<textarea wrap cols=45 rows=5 name=description>$description</textarea>
</td>
</tr>


<tr>
<th align=left valign=top>
Mission Statement
</td>
<td>
<textarea wrap cols=45 rows=5 name=mission_statement>$mission_statement</textarea>
</td>
</tr>

<tr>
<td colspan=2 align=center>
<input type=submit value=Continue>
</td>
</tr>

</table>

</form>

</blockquote>
[ad_footer]
"









