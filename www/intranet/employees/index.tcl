# $Id: index.tcl,v 3.3.2.2 2000/03/17 08:56:34 mbryzek Exp $
#
# File: /www/intranet/employees/index.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Top level admin view of all employees
# 

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set_form_variables 0
# optional: status_id

set db [ns_db gethandle]

# can the user make administrative changes to this page
set user_admin_p [im_is_user_site_wide_or_intranet_admin $db $user_id]

set return_url [ad_partner_url_with_query]

if { ![exists_and_not_null order_by] } {
    set order_by "Name"
}

# Offer admins a link to a different view
if { $user_admin_p } {
    set view_types "<a href=admin/index.tcl>Admin View</a> | " 
}

append view_types "<a href=org-chart.tcl>Org Chart</a> | <b>Standard View</b>"

set order_by_clause ""
switch $order_by {
    "Name" { set order_by_clause "order by upper(last_name), upper(first_names)" }
    "Email" { set order_by_clause "order by upper(email), upper(last_name), upper(first_names)" }
    "AIM" { set order_by_clause "order by upper(aim_screen_name), upper(last_name), upper(first_names)" }
    "Cell Phone" { set order_by_clause "order by upper(cell_phone), upper(last_name), upper(first_names)" }
    "Home Phone" { set order_by_clause "order by upper(home_phone), upper(last_name), upper(first_names)" }
    "Work Phone" { set order_by_clause "order by upper(work_phone), upper(last_name), upper(first_names)" }
}

set page_title "Employees"
set context_bar [ad_context_bar [list "/" Home] [list ../index.tcl "Intranet"] $page_title]

set page_body "
<table width=100% cellpadding=0 cellspacing=0 border=0>
  <tr><td align=right>$view_types</td></tr>
</table>
"

set selection [ns_db select $db \
 	"select u.last_name||', '||u.first_names as name, u.user_id,
                u.email, c.aim_screen_name, c.home_phone, c.work_phone, c.cell_phone
           from users_active u, users_contact c
          where u.user_id=c.user_id(+) 
            and ad_group_member_p ( u.user_id, [im_employee_group_id] ) = 't'
            $order_by_clause"]
            

set results ""
set bgcolor(0) " bgcolor=\"[ad_parameter TableColorOdd Intranet white]\""
set bgcolor(1) " bgcolor=\"[ad_parameter TableColorEven Intranet white]\""
set ctr 0
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append results "
<tr$bgcolor([expr $ctr % 2])>
  <td valign=top>[ad_partner_default_font] <a href=../users/view.tcl?[export_url_vars user_id]>$name</a> </font></td>
  <td valign=top>[ad_partner_default_font] <a href=mailto:$email>$email</a> </font></td>
  <td valign=top>[ad_partner_default_font] [util_decode $aim_screen_name "" "&nbsp;" $aim_screen_name] </font></td>
  <td valign=top>[ad_partner_default_font] [util_decode $cell_phone "" "&nbsp;" $cell_phone] </font></td>
  <td valign=top>[ad_partner_default_font] [util_decode $home_phone "" "&nbsp;" $home_phone] </font></td>
  <td valign=top>[ad_partner_default_font] [util_decode $work_phone "" "&nbsp;" $work_phone] </font></td>
</tr>
"
    incr ctr
}


if { [empty_string_p $results] } {
    set results "<ul><li><b> There are currently no employees</b></ul>\n"
} else {
    set column_headers [list Name "Email" AIM "Cell Phone" "Home Phone" "Work Phone"]

    set url "index.tcl"
    set query_string [export_ns_set_vars url [list order_by]]
    if { [empty_string_p $query_string] } {
	append url "?"
    } else {
	append url "?$query_string&"
    }
    set table "
<table width=100% cellpadding=1 cellspacing=2 border=0>
<tr bgcolor=\"[ad_parameter TableColorHeader intranet white]\">
"
    foreach col $column_headers {
	if { [string compare $order_by $col] == 0 } {
	    append table "  <th>$col</th>\n"
	} else {
	    append table "  <th><a href=\"${url}order_by=[ns_urlencode $col]\">$col</a></th>\n"
	}
    }
    set results "
<br>
$table
</tr>
$results
</table>
"
}


append page_body "
$results
<ul>
"
if { $user_admin_p } {
    append page_body "  <li> <a href=/groups/member-add.tcl?role=member&[export_url_vars return_url]&group_id=[im_employee_group_id]>Add an employee</a>\n"
}

set spam_link "/groups/[ad_parameter EmployeeGroupShortName intranet employee]/spam.tcl?sendto=members"

append page_body "
  <li> Look at all <a href=with-portrait.tcl>employees with portraits</a>
  <li> <a href=$spam_link>Spam all employees</a>
  <li> <a href=aim.tcl>Download</a> an AIM's [ad_parameter SystemName] \"buddy\" list
</ul>
"

ns_db releasehandle $db

ns_return 200 text/html [ad_partner_return_template]
