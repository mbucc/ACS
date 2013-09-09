# /www/intranet/employees/index.tcl

ad_page_contract {
    Top level view of all employees

    @param viewing_group_id stores group_id
    @param group_id user group ID
    @param order_by what to order rows by
    @param start_idx starting ID of row
    @param how_many max number of rows we display
    @param letter first letter of last name?

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000

    @cvs-id index.tcl,v 3.29.2.8 2000/10/29 23:44:26 tony Exp
} {
    { viewing_group_id:integer "" }
    { group_id:integer "" }
    { order_by "Name" }
    { start_idx:integer "1" }
    { how_many:integer "" }
    { letter:trim "scroll" }
}


# Allow people to call this page with "group_id" - transfer it to 
# viewing_group_id to save the variable
if { [empty_string_p $viewing_group_id] && ![empty_string_p $group_id] } {
    set viewing_group_id $group_id
}
set default_order_by "order by upper(last_name), upper(first_names)"

set page_title "Employees"
set context_bar [ad_context_bar_ws $page_title]
set page_focus "im_header_form.keywords"

set user_id [ad_maybe_redirect_for_registration]

if { [empty_string_p $how_many] || $how_many < 1 } {
    set how_many [ad_parameter NumberResultsPerPage intranet 50]
}
set end_idx [expr $start_idx + $how_many - 1]



# can the user make administrative changes to this page
set user_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]

set return_url [im_url_with_query]

# Offer admins a link to a different view
if { $user_admin_p } {
    set view_types "<a href=admin/index?[export_ns_set_vars url]>Admin View</a> | " 
}

append view_types "<a href=org-chart>Org Chart</a> | <b>Standard View</b>"

set order_by_clause ""
switch $order_by {
    "Name" { set order_by_clause "" }
    "Email" { set order_by_clause "order by upper(email)" }
    "AIM" { set order_by_clause "order by upper(aim_screen_name)" }
    "Cell Phone" { set order_by_clause "order by upper(cell_phone)" }
    "Home Phone" { set order_by_clause "order by upper(home_phone)" }
    "Work Phone" { set order_by_clause "order by upper(work_phone)" }
}

set team_list [list "0" "All"]
set team_group_id [im_team_group_id]
set team_query "select group_id, group_name
                from user_groups 
                where parent_group_id = :team_group_id
                order by group_name"

db_foreach team_select $team_query {
    lappend team_list $group_id $group_name
} 

set team_slider [im_slider viewing_group_id $team_list $viewing_group_id "start_idx group_id"]

set office_list [list "0" "All"]
set office_group_id [im_office_group_id] 
set office_query "select group_id, group_name
                  from user_groups 
                  where parent_group_id = :office_group_id
                  order by group_name"

db_foreach office_select $office_query {
    lappend office_list $group_id $group_name
} 

set office_slider [im_slider viewing_group_id $office_list $viewing_group_id "start_idx group_id"]

set criteria [list]


if { ![empty_string_p $viewing_group_id] && $viewing_group_id>0 } {
    set viewing_group_id $viewing_group_id
    set group_name [db_string group_name_find \
	    "select group_name from user_groups where group_id=:viewing_group_id"]
    append page_title " in group \"$group_name\""
    lappend criteria "ad_group_member_p(u.user_id, :viewing_group_id) = 't'"
}
if { ![empty_string_p $letter] && [string compare $letter "all"] != 0 && [string compare $letter "scroll"] != 0 } {
    set letter [string toupper $letter]
    lappend criteria "im_first_letter_default_to_a(u.last_name)=:letter"
}

if { [llength $criteria] > 0 } {
    set where_clause [join $criteria "\n         and "]
} else {
    set where_clause "1=1"
}

set employee_data_sql "select u.last_name || ', ' || u.first_names as name, u.user_id,
                u.email, c.aim_screen_name, c.home_phone, c.work_phone, c.cell_phone
           from im_employees_active u, users_contact c
          where u.user_id=c.user_id(+) 
            and $where_clause [util_decode $order_by_clause "" $default_order_by $order_by_clause]"

if { [string compare $letter "all"] == 0 } {
    # Set these limits to negative values to deactivate them
    set total_in_limited -1
    set how_many -1
    set employee_query $employee_data_sql
} else {
    set employee_query [im_select_row_range $employee_data_sql $start_idx $end_idx]
    # We can't get around counting in advance if we want to be able to sort inside
    # the table on the page for only those users in the query results
    set total_in_limited [db_string advance_count \
	    "select count(1) from im_employees_active u where $where_clause"]
}

set results ""
set bgcolor(0) " bgcolor=\"[ad_parameter TableColorOdd Intranet white]\""
set bgcolor(1) " bgcolor=\"[ad_parameter TableColorEven Intranet white]\""
set ctr 0

db_foreach employee_select $employee_query {
    append results "
<tr$bgcolor([expr $ctr % 2])>
  <td valign=top> <a href=../users/view?[export_url_vars user_id]>$name</a> </td>
  <td valign=top> <a href=mailto:$email>$email</a> </td>
  <td valign=top> [util_decode $aim_screen_name "" "&nbsp;" $aim_screen_name] </td>
  <td valign=top> [util_decode $work_phone "" "&nbsp;" $work_phone] </td>
  <td valign=top> [util_decode $cell_phone "" "&nbsp;" $cell_phone] </td>
  <td valign=top> [util_decode $home_phone "" "&nbsp;" $home_phone] </td>
</tr>
"
    incr ctr
    if { $how_many > 0 && $ctr >= $how_many } {
	break
    }
} 

if { $ctr == $how_many && $end_idx < $total_in_limited } {
    # This means that there are rows that we decided not to return
    # Include a link to go to the next page
    set next_start_idx [expr $end_idx + 1]
    set next_page "<a href=index?start_idx=$next_start_idx&[export_ns_set_vars url [list start_idx]]>Next Page</a>"
} else {
    set next_page ""
}

if { $start_idx > 1 } {
    # This means we didn't start with the first row - there is
    # at least 1 previous row. add a previous page link
    set previous_start_idx [expr $start_idx - $how_many]
    if { $previous_start_idx < 1 } {
	set previous_start_idx 1
    }
    set previous_page "<a href=index?start_idx=$previous_start_idx&[export_ns_set_vars url [list start_idx]]>Previous Page</a>"
} else {
    set previous_page ""
}

set navbar [im_default_nav_header $previous_page $next_page "[im_url_stub]/employees/search" "" "Search"]

set column_headers [list Name "Email" AIM "Work Phone" "Cell Phone" "Home Phone" ]

set table "
<table width=100% cellpadding=2 cellspacing=2 border=0>
<tr>
  <td align=center valign=top colspan=[llength $column_headers]><font size=-1>
    [im_employees_alpha_bar $letter "start_idx"]</font>
  </td>
</tr>
"

if { [empty_string_p $results] } {
    append table "<tr><td colspan=[llength $column_headers]><ul><li><b> There are currently no employees</b></ul></td></tr>\n"
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
    append table "
</tr>
$results
"
}
append table "
<tr>
  <td align=center colspan=[llength $column_headers]>[im_maybe_insert_link $previous_page $next_page]</td>
</tr>
</table>
"

set page_body "
<table width=100% cellpadding=0 cellspacing=2 border=0>
  <tr bgcolor=eeeeee>
    <th>Office</th>
    <th>Team</th>
    <th>$view_types</th>
  </tr>
  <tr>
    <td align=center valign=top><font size=-1>$office_slider</font></td>
    <td align=center valign=top><font size=-1>$team_slider</font></td>
    <td align=center valign=top><font size=-1>$navbar</font></td>
  </tr>
</table>

$table
<ul>
"

if { ![empty_string_p $results] } {

    set spam_link "/groups/[ad_parameter EmployeeGroupShortName intranet employee]/spam?sendto=all"
    append page_body "
  <li> Look at all <a href=with-portrait>employees with portraits</a>
  <li> <a href=$spam_link>Spam all employees</a>
  <li> <a href=aim>Download</a> an AIM's [ad_parameter SystemName] \"buddy\" list
  <li> <a href=skills>View employees</a> and their special skills
"
}

append page_body "</ul>\n"



doc_return  200 text/html [im_return_template]
