# /www/intranet/customers/index.tcl

ad_page_contract {
    Shows all customers. Lots of dimensional sliders

    @param status_id if specified, limits view to those of this status
    @param type_id   if specified, limits view to those of this type
    @param order_by  Specifies order for the table
    @param view_type Specifies which customers to see

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000
    @cvs-id index.tcl,v 3.20.2.7 2000/09/22 01:38:28 kevin Exp

} {
    { status_id:integer "" }
    { type_id:integer "0" }
    { order_by "Customer" }
    { view_type "all" }
}

set user_id [ad_maybe_redirect_for_registration]

if { ![exists_and_not_null status_id] } {
    # Default status is Current - select the id once and memoize it
    set status_id [im_memoize_one select_customer_status_id \
	    "select customer_status_id 
               from im_customer_status
              where upper(customer_status) = 'CURRENT'"]
}

set view_types [list "mine" "Mine" "all" "All" "unassigned" "Unassigned"]


# status_types will be a list of pairs of (project_status_id, project_status)
set status_types [im_memoize_list select_customer_status_types \
	"select customer_status_id, customer_status
           from im_customer_status
          order by lower(customer_status)"]
lappend status_types 0 All


# customer_types will be a list of pairs of (customer_type_id, customer_type)
set customer_types [im_memoize_list select_customers_types \
	"select customer_type_id, customer_type
           from im_customer_types
          order by lower(customer_type)"]
lappend customer_types 0 All



# Now let's generate the sql query
set criteria [list]

set bind_vars [ns_set create]
if { ![empty_string_p $status_id] && $status_id != 0 } {
    ns_set put $bind_vars status_id $status_id
    lappend criteria "c.customer_status_id=:status_id"
}


if { $type_id > 0 } {
    ns_set put $bind_vars type_id $type_id
    lappend criteria "c.customer_type_id=:type_id"
}


set extra_tables [list]
if { [string compare $view_type "mine"] == 0 } {
    ns_set put $bind_vars user_id $user_id
    lappend criteria "ad_group_member_p ( :user_id, g.group_id ) = 't'"
} elseif { [string compare $view_type "unassigned"] == 0 } {
    ns_set put $bind_vars user_id $user_id
    lappend criteria "not exists (select 1 from user_group_map where user_group_map.group_id = g.group_id)"
}

set order_by_clause ""
switch $order_by {
    "Phone" { set order_by_clause "order by upper(phone_work), upper(group_name)" }
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
set context_bar [ad_context_bar_ws $page_title]
set page_focus "im_header_form.keywords"

set sql "select c.group_id as customer_id, g.group_name, c.primary_contact_id, status.customer_status,
                ab.last_name||', '||ab.first_names as name, ab.email, ab.phone_work
           from user_groups g, im_customers c, 
           im_customer_status status, im_customer_types customer_type,
           address_book ab $extra_table
          where c.group_id = g.group_id(+)
            and c.primary_contact_id=ab.address_book_id(+)
            and c.customer_type_id = customer_type.customer_type_id (+)
            and c.customer_status_id=status.customer_status_id(+) $where_clause $order_by_clause"
            

set results ""
set bgcolor(0) " bgcolor=\"[ad_parameter TableColorOdd Intranet white]\""
set bgcolor(1) " bgcolor=\"[ad_parameter TableColorEven Intranet white]\""
set ctr 0
db_foreach customer_select $sql -bind $bind_vars {
    append results "
<tr$bgcolor([expr $ctr % 2])>
  <td valign=top><a href=view?group_id=$customer_id>$group_name</a></td>
  <td valign=top>$customer_status</td>
  <td valign=top>[util_decode $name ", " "&nbsp;" $name]</td>
  <td valign=top>[util_decode $email "" "&nbsp;" "<a href=mailto:$email>$email</a>"]</td>
  <td valign=top>[util_decode $phone_work "" "&nbsp;" $phone_work]</td>
</tr>
"
    incr ctr
}

set column_headers [list Customer Status "Contact Person" Email Phone]
set table "<table width=100% cellpadding=1 cellspacing=2 border=0>\n"

if { [empty_string_p $results] } {
    set results "<tr><td><ul><li><b> There are currently no customers</b></ul></td></tr>\n"
} else {
    set url "index?"

    set query_string [export_ns_set_vars url [list order_by]]
    if { ![empty_string_p $query_string] } {
	append url "$query_string&"
    }
    append table "<tr bgcolor=\"[ad_parameter TableColorHeader intranet white]\">\n"
    foreach col $column_headers {
	if { [string compare $order_by $col] == 0 } {
	    append table "  <th>$col</th>\n"
	} else {
	    append table "  <th><a href=\"${url}order_by=[ns_urlencode $col]\">$col</a></th>\n"
	}
    }
    set results "
$table
</tr>
$results
</table>
"
}


set page_body "
<table width=100% border=0 cellspacing=1 cellpadding=0>
  <tr bgcolor=eeeeee>
    <th valign=top><font size=-1>View</font></th>
    <th valign=top><font size=-1>Customer status</font></th>
    <th valign=top><font size=-1>Customer type</font></th>
    <th valign=top><font size=-1>Search</font></th>
  </tr>
  <tr>
    <td align=center valign=top><font size=-1>
       [im_slider view_type $view_types "" [list start_idx]]
       </font></td>
    <td align=center valign=top><font size=-1>
       [im_slider status_id $status_types "" [list start_idx]]
       </font></td>
    <td align=center valign=top><font size=-1>
       [im_slider type_id $customer_types "" [list start_idx]]
       </font></td>
    <td align=center valign=top><font size=-1>
       [im_default_nav_header "" "" "search"]
    </font></td>
  </tr>
</table>

$results

<p><a href=ae>Add a customer</a>
"



 
doc_return  200 text/html [im_return_template]
