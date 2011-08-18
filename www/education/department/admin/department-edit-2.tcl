#
# /www/education/department/admin/department-edit-2.tcl
#
# by randyg@arsdigita.com, aileen@arsdigita.com, January 2000
#
# this page allows the user to edit informaiton about a department
#

ad_page_variables {
    group_name
    {department_number ""}
    {external_homepage_url ""}
    {mailing_address ""}
    {phone_number ""}
    {fax_number ""}
    {inquiry_email ""}
    {description ""}
    {mission_statement ""}
}

# note that we do not require the department_id because we
# get that from looking up the session_id


set db [ns_db gethandle]

# set the user and group information
set id_list [edu_group_security_check $db edu_department]
set user_id [lindex $id_list 0]
set department_id [lindex $id_list 1]
set department_name [lindex $id_list 2]


set exception_text ""
set exception_count 0

if {[empty_string_p $group_name]} {
    append exception_text "<li> You must provide a name for the new department."
    incr exception_count
}



# if an email is provided, make sure that it is of the correct for.

if {[info exists inquiry_email] && ![empty_string_p $inquiry_email] && ![philg_email_valid_p $inquiry_email]} {
    incr exception_count
    append exception_text "<li>The inquiry email address that you typed doesn't look right to us.  Examples of valid email addresses are 
<ul>
<li>Alice1234@aol.com
<li>joe_smith@hp.com
<li>pierre@inria.fr
</ul>
"
}


# if a phone number is provided, check its form

if {![empty_string_p $phone_number] && ![edu_phone_number_p $phone_number]} {
    incr exception_count
    append exception_text "<li> The phone number you have entered is not in the correct form.  It must be of the form XXX-XXX-XXXX \n"
}


# if a fax nubmer is provided, check its form

if {![empty_string_p $fax_number] && ![edu_phone_number_p $fax_number]} {
    incr exception_count
    append exception_text "<li> The fax number you have entered is not in the correct form.  It must be of the form XXX-XXX-XXXX \n"
}


if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}


if {[string compare $external_homepage_url "http://"] == 0} {
    set external_homepage_url ""
}


ns_db releasehandle $db

ns_return 200 text/html "

[ad_header "Department Administration @ [ad_system_name]"]
<h2>Confirm Department Information</h2>

[ad_context_bar_ws [list "/department/" "Departments"] [list "" "Department Administration"] "Edit Department Information"]

<hr>
<blockquote>

<form method=post action=\"department-edit-3.tcl\">

[export_form_vars group_name department_number external_homepage_url mailing_address phone_nubmer fax_number inquery_email description mission_statement]

<table>

<tr>
<th align=left valign=top>
Department Name
</td>
<td>
$group_name
</td>
</tr>

<tr>
<th align=left valign=top>
Department Number
</td>
<td>
$department_number
</td>
</tr>

<tr>
<th align=left valign=top>
External Homepage URL
</td>
<td>
$external_homepage_url
</td>
</tr>

<tr>
<th align=left valign=top>
Mailing Address
</td>
<td>
$mailing_address
</td>
</tr>


<tr>
<th align=left valign=top>
Phone Number
</td>
<td>
$phone_number
</td>
</tr>

<tr>
<th align=left valign=top>
Fax Number
</td>
<td>
$fax_number
</td>
</tr>

<tr>
<th align=left valign=top>
Inquiry Email Address
</td>
<td>
$inquiry_email
</td>
</tr>


<tr>
<th align=left valign=top>
Description
</td>
<td>
[address_book_display_as_html $description]
</td>
</tr>


<tr>
<th align=left valign=top>
Mission Statement
</td>
<td>
[address_book_display_as_html $mission_statement]
</td>
</tr>

<tr>
<td colspan=2 align=center>
<Br>
<input type=submit value=\"Edit Department Information\">
</td>
</tr>

</table>

</form>

</blockquote>
[ad_footer]
"









