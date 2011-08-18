#
# /www/education/department/one.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page displays information about a single department
#

set department_id [ad_get_client_property education edu_department]

if {[empty_string_p $department_id]} {
    ad_returnredirect "/education/util/group-select.tcl?group_type=edu_class&return_url=[ns_urlencode [ns_conn url]?[ns_conn query]]"
    return
}

set db [ns_db gethandle]

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
    ad_return_complaint 1 "<li> The department you have requested does not exist."
    return
} else {
    set_variables_after_query
}

if {[string compare $external_homepage_url "http://"] == 0} {
    set external_homepage ""
} else {
    set external_homepage "<a href=$external_homepage_url>$external_homepage_url</a>"
}


set return_string "
[ad_header "Departments @ [ad_system_name]"]

<h2>$department_name</h2>

[ad_context_bar_ws_or_index [list "" Departments] "One Department"]

<hr>
<blockquote>

<table>

<tr>
<th align=left valign=top>
Department Name
</td>
<td>
$department_name
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
$external_homepage
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

</table>

</blockquote>

[ad_footer]
"

ns_db releasehandle $db 

ns_return 200 text/html $return_string






