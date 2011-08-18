# $Id: view.tcl,v 3.3.2.1 2000/03/17 08:23:03 mbryzek Exp $
# File: /www/intranet/offices/view.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Shows all info about a specified office
# 

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set_form_variables
# group_id

set caller_group_id $group_id

set return_url [ad_partner_url_with_query]

set db [ns_db gethandle]

set selection [ns_db 0or1row $db \
	"select g.group_name, g.short_name, o.*, u.first_names || ' ' || u.last_name as name
           from im_offices o, user_groups g, users u
          where g.group_id = $caller_group_id
            and g.group_id=o.group_id(+)
            and o.contact_person_id=u.user_id(+)"]
    
if { [empty_string_p $selection] } {
    ad_return_error "Error" "Office doesn't exist"
    return
}
set_variables_after_query

set years_experience ""

if { 0 } {
    set years_experience [database_to_tcl_string_or_null $db \
	"select round(sum((sysdate - first_experience)/365)) 
           from im_users 
          where group_id = $caller_group_id"]
}


set page_title "$group_name"
set context_bar [ad_context_bar [list "/" Home] [list "../" "Intranet"] [list index.tcl "Offices"] "One office"]
set page_body ""

if { ![empty_string_p $years_experience] } {
    append page_body "<center><blockquote>
<em>$years_experience [util_decode $years_experience 1 year years] of combined experience</em>
</blockquote></center>
"
}

append page_body "
<table cellpadding=3>
<tr>
  <th valign=top align=right>Short Name:</th>
  <td valign=top>$short_name</td>
</tr>

<tr>
  <th valign=top align=right>Addess:</th>
  <td valign=top>[im_format_address $address_line1 $address_line2 $address_city $address_state $address_postal_code]</td>
</tr>

<tr>
  <th valign=top align=right>Phone:</TH>
  <td valign=top>$phone</td>
</tr>

<tr>
  <th valign=top align=right>Fax:</TH>
  <td valign=top>$fax</td>
</tr>

<tr>
  <th valign=top align=right>Contact:</TH>
  <td valign=top>
"
if { [empty_string_p $contact_person_id] } {
    append page_body "    <a href=primary-contact.tcl?group_id=$caller_group_id&limit_to_users_in_group_id=[im_employee_group_id]>Add primary contact</a>\n"
} else {
    append page_body "
    <a href=../users/view.tcl?user_id=$contact_person_id>$name</a>
    (<a href=primary-contact.tcl?group_id=$caller_group_id>change</a> |
    <a href=primary-contact-delete.tcl?[export_url_vars group_id return_url]>remove</a>)
"
}

append page_body "
  </td>
</tr>

<tr>
  <th align=right valign=top>Landlord:</TH>
  <td valign=top>$landlord</td>
</tr>

<tr>
  <th align=right valign=top>Security:</TH>
  <td valign=top>$security</td>
</tr>

<tr>
  <th align=right valign=top>Other<Br> information:</TH>
  <td valign=top>$note</td>
</tr>


<tr>
  <th></th>
  <td align=center>(<a href=ae.tcl?group_id=$caller_group_id&[export_url_vars return_url]>edit</A>)</td>
</tr>

</table>

"

set selection [ns_db select $db \
	"select u.user_id, u.first_names || ' ' || u.last_name as name
           from users_active u
          where ad_group_member_p ( u.user_id, $caller_group_id ) = 't'
       order by upper(name)"]

set employees ""
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append employees "  <li><a href=../users/view.tcl?[export_url_vars user_id]>$name</a>\n"
    append employees " (<a href=/groups/member-remove-2.tcl?[export_url_vars group_id user_id return_url]>remove</a>)\n"
}

if { [empty_string_p $employees] } {
    set employees "<li><i>No employees listed</i>\n"
}

append page_body "
<h4>Employees</h4>

<ul>
$employees

   <p><li><a href=/groups/member-add.tcl?limit_to_users_in_group_id=[im_employee_group_id]&role=member&[export_url_vars group_id return_url]>Add an employee</a>
   <li><a href=/groups/[ad_urlencode $short_name]/spam.tcl?sendto=members>Send email to this office</a>
</ul>
"

ns_db releasehandle $db

ns_return 200 text/html [ad_partner_return_template]