# $Id: index.tcl,v 3.2.2.1 2000/03/17 08:22:52 mbryzek Exp $
# File: /www/intranet/customers/index.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Shows all customers. Lots of dimensional sliders
# 

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set_form_variables 0
# optional: status_id

if { ![exists_and_not_null status_id] } {
    # Default status is Current - select the id once and memoize it
    set status_id [ad_partner_memoize_one \
	    "select customer_status_id 
               from im_customer_status
              where upper(customer_status) = 'CURRENT'" customer_status_id]
}
if { ![exists_and_not_null order_by] } {
    set order_by "Customer"
}

if { ![exists_and_not_null mine_p] } {
    set mine_p "t"
}
set view_types [list "t" "Mine" "f" "All"]


# status_types will be a list of pairs of (project_status_id, project_status)
set status_types [ad_partner_memoize_list_from_db \
	"select customer_status_id, customer_status
           from im_customer_status
          order by display_order, lower(customer_status)" [list customer_status_id customer_status]]
lappend status_types 0 All

# Now let's generate the sql query
set criteria [list]

if { ![empty_string_p $status_id] && $status_id != 0 } {
    lappend criteria "c.customer_status_id=$status_id"
}

set extra_tables [list]
if { [string compare $mine_p "t"] == 0 } {
    lappend criteria "ad_group_member_p ( $user_id, g.group_id ) = 't'"
}

set order_by_clause ""
switch $order_by {
    "Phone" { set order_by_clause "order by upper(work_phone), upper(group_name)" }
    "Email" { set order_by_clause "order by upper(email), upper(group_name)" }
    "Status" { set order_by_clause "order by upper(customer_status), upper(group_name)" }
    "Contact Person" { set order_by_clause "order by upper(last_name), upper(first_names), upper(group_name)" }
    "Customer" { set order_by_clause "order by upper(group_name)" }
}

set extra_table ""
if { [llength $extra_tables] > 0 } {
    set extra_table ", [join $extra_tables ","]"
}

set where_clause [join $criteria " and\n            "]
if { ![empty_string_p $where_clause] } {
    set where_clause " and $where_clause"
}

set page_title "Customers"
set context_bar [ad_context_bar [list "/" Home] [list ../index.tcl "Intranet"] $page_title]

set db [ns_db gethandle]
set selection [ns_db select $db \
	"select c.group_id as customer_id, g.group_name, c.primary_contact_id, status.customer_status,
                u.last_name||', '||u.first_names as name, u.email, uc.work_phone
           from user_groups g, im_customers c, im_customer_status status, users u, users_contact uc$extra_table
          where c.group_id = g.group_id
            and c.primary_contact_id=u.user_id(+)
            and c.primary_contact_id=uc.user_id(+)
            and c.customer_status_id=status.customer_status_id $where_clause $order_by_clause"]
            

set results ""
set bgcolor(0) " bgcolor=\"[ad_parameter TableColorOdd Intranet white]\""
set bgcolor(1) " bgcolor=\"[ad_parameter TableColorEven Intranet white]\""
set ctr 0
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append results "
<tr$bgcolor([expr $ctr % 2])>
  <td valign=top>[ad_partner_default_font]<a href=view.tcl?group_id=$customer_id>$group_name</a></font></td>
  <td valign=top>[ad_partner_default_font]$customer_status</font></td>
  <td valign=top>[ad_partner_default_font][util_decode $name ", " "&nbsp;" $name]</font></td>
  <td valign=top>[ad_partner_default_font][util_decode $email "" "&nbsp;" "<a href=mailto:$email>$email</a>"]</font></td>
  <td valign=top>[ad_partner_default_font][util_decode $work_phone "" "&nbsp;" $work_phone]</font></td>
</tr>
"
    incr ctr
}


if { [empty_string_p $results] } {
    set results "<ul><li><b> There are currently no customers</b></ul>\n"
} else {
    set column_headers [list Customer Status "Contact Person" Email Phone]
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




set page_body "
[ad_partner_default_font "size=-1"]
Customer status: [im_slider status_id $status_types]
<br>View: [im_slider mine_p $view_types]
</font>
<p>
$results

<p><a href=ae.tcl>Add a customer</a>
"

ns_db releasehandle $db

 
ns_return 200 text/html [ad_partner_return_template]
