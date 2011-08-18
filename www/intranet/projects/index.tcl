# $Id: index.tcl,v 3.2.2.2 2000/03/17 08:56:38 mbryzek Exp $
# File: /www/intranet/projects/index.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Purpose: lists all projects with dimensional sliders
#

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set_form_variables 0
# optional: status_id, type_id

if { ![exists_and_not_null status_id] } {
    # Default status is OPEN - select the id once and memoize it
    set status_id [ad_partner_memoize_one \
	    "select project_status_id 
               from im_project_status 
              where upper(project_status) = 'OPEN'" project_status_id]
}
if { ![exists_and_not_null type_id] } {
    set type_id 0
}
if { ![exists_and_not_null order_by] } {
    set order_by "Name"
}
if { ![exists_and_not_null mine_p] } {
    set mine_p "t"
}
set view_types [list "t" "Mine" "f" "All"]

# status_types will be a list of pairs of (project_status_id, project_status)
set status_types [ad_partner_memoize_list_from_db \
	"select project_status_id, project_status
           from im_project_status
          order by display_order, lower(project_status)" [list project_status_id project_status]]
lappend status_types 0 All

# project_types will be a list of pairs of (project_type_id, project_type)
set project_types [ad_partner_memoize_list_from_db \
	"select project_type_id, project_type
           from im_project_types
          order by display_order, lower(project_type)" [list project_type_id project_type]]
lappend project_types 0 All


set page_title "Projects"
set context_bar [ad_context_bar [list "/" Home] [list "../" "Intranet"] $page_title]

set page_body "
<table width=100% border=0>
<tr>
  <td valign=top>[ad_partner_default_font "size=-1"]
    Project status: [im_slider status_id $status_types]
    <br>Project type: [im_slider type_id $project_types]
    <br>View: [im_slider mine_p $view_types]
  </font></td>
  <td align=right valign=top>[ad_partner_default_font "size=-1"]
    <a href=\"../allocations/index.tcl\">Allocations</a> | 
    <a href=\"money.tcl\">Financial View</a>
  </font></td>
</tr>
</table>
"

# Now let's generate the sql query
set criteria [list]

if { ![empty_string_p $status_id] && $status_id != 0 } {
    lappend criteria "p.project_status_id=$status_id"
}
if { ![empty_string_p $type_id] && $type_id != 0 } {
    lappend criteria "p.project_type_id=$type_id"
}
set extra_table ""
if { [string compare $mine_p "t"] == 0 } {
    lappend criteria "ad_group_member_p ( $user_id, p.group_id ) = 't'"
}

set order_by_clause ""
switch $order_by {
    "Type" { set order_by_clause "order by project_type, upper(group_name)" }
    "Status" { set order_by_clause "order by project_status, upper(group_name)" }
    "Project Lead" { set order_by_clause "order by upper(last_name), upper(first_names), upper(group_name)" }
    "URL" { set order_by_clause "order by upper(url), upper(group_name)" }
    "Name" { set order_by_clause "order by upper(group_name)" }
}

set where_clause [join $criteria " and\n            "]
if { ![empty_string_p $where_clause] } {
    set where_clause " and $where_clause"
}

set db [ns_db gethandle]
set selection [ns_db select $db \
	"select user_group_name_from_id(p.group_id) as group_name, p.group_id, p.group_id, 
                u.first_names||' '||u.last_name as lead_name, u.user_id, 
                im_proj_type_from_id(p.project_type_id)  as project_type, 
                im_proj_status_from_id(p.project_status_id)  as project_status,
                im_proj_url_from_type(p.group_id, 'website') as url
           from im_projects p, users u$extra_table
          where p.project_lead_id=u.user_id(+) $where_clause
            and p.parent_id is null $order_by_clause"]

set results ""
set bgcolor(0) " bgcolor=\"[ad_parameter TableColorOdd Intranet white]\""
set bgcolor(1) " bgcolor=\"[ad_parameter TableColorEven Intranet white]\""
set ctr 0
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    set url [im_maybe_prepend_http $url]
    if { [empty_string_p $url] } {
	set url_string "&nbsp;"
    } else {
	set url_string "<a href=\"$url\">$url</a>"
    }
    append results "
<tr$bgcolor([expr $ctr % 2])>
  <td valign=top>[ad_partner_default_font]<a href=view.tcl?[export_url_vars group_id]>$group_name</a></font></td>
  <td valign=top>[ad_partner_default_font]$project_type</font></td>
  <td valign=top>[ad_partner_default_font]$project_status</font></td>
  <td valign=top>[ad_partner_default_font]<a href=../users/view.tcl?[export_url_vars user_id]>$lead_name</a></font></td>
  <td valign=top>[ad_partner_default_font]$url_string</font></td>
</tr>
"
    incr ctr
}

ns_db releasehandle $db

if { [empty_string_p $results] } {
    append page_body "<ul><li><b> There are currently no projects</b></ul>\n"
} else {
    set column_headers [list Name Type Status "Project Lead" URL]
    set url "index.tcl"
    set query_string [export_ns_set_vars url [list order_by]]
    if { [empty_string_p $query_string] } {
	append url "?"
    } else {
	append url "?$query_string&"
    }
    set table "
<table width=100% cellpadding=2 cellspacing=2 border=0>
<tr bgcolor=\"[ad_parameter TableColorHeader intranet white]\">
"
    foreach col $column_headers {
	if { [string compare $order_by $col] == 0 } {
	    append table "  <th>$col</th>\n"
	} else {
	    append table "  <th><a href=\"${url}order_by=[ns_urlencode $col]\">$col</a></th>\n"
	}
    }
    append page_body "
<br>
$table
</tr>
$results
</table>
"
}

append page_body "<p><a href=ae.tcl>Add a project</a>\n"

ns_return 200 text/html [ad_partner_return_template]