# /www/intranet/projects/index.tcl

ad_page_contract { 
    List all projects with dimensional sliders.

    @param order_by project display order 
    @param include_subprojects_p whether to include sub projects
    @param mine_p show my projects or all projects
    @param status_id criteria for project status
    @param type_id criteria for project_type_id
    @param letter criteria for im_first_letter_default_to_a(ug.group_name)
    @param start_idx the starting index for query
    @param how_many how many rows to return

    @author mbryzek@arsdigita.com
    @cvs-id index.tcl,v 3.24.2.9 2000/09/22 01:38:44 kevin Exp
} {
    { order_by "Name" }
    { include_subprojects_p "f" }
    { mine_p "t" }
    { status_id "" } 
    { type_id:integer "0" } 
    { letter "scroll" }
    { start_idx:integer "1" }
    { how_many "" }
    { merge_group_id_1 "" }
}

# User id already verified by filters
set user_id [ad_get_user_id]

if { [empty_string_p $status_id] } {
    # Default status is OPEN - select the id once and memoize it
    set status_id [im_memoize_one select_project_open_status_id \
	    "select project_status_id
               from im_project_status
              where upper(project_status) = 'OPEN'"]
}

set view_types [list "t" "Mine" "f" "All"]
set subproject_types [list "t" "Yes" "f" "No"]


# status_types will be a list of pairs of (project_status_id, project_status)
set status_types [im_memoize_list select_project_status_types \
	"select project_status_id, project_status
           from im_project_status
          order by lower(project_status)"]
lappend status_types 0 All

# project_types will be a list of pairs of (project_type_id, project_type)
set project_types [im_memoize_list select_project_types \
	"select project_type_id, project_type
           from im_project_types
          order by lower(project_type)"]
lappend project_types 0 All

set page_title "Projects"
set context_bar [ad_context_bar_ws $page_title]
set page_focus "im_header_form.keywords"

# Now let's generate the sql query
set criteria [list]

if { ![empty_string_p $status_id] && $status_id > 0 } {
    lappend criteria "p.project_status_id=:status_id"
}
if { ![empty_string_p $type_id] && $type_id != 0 } {
    lappend criteria "p.project_type_id=:type_id"
}

if { [string compare $mine_p "t"] == 0 } {
    lappend criteria "ad_group_member_p ( :user_id, p.group_id ) = 't'"
}
if { ![empty_string_p $letter] && [string compare $letter "all"] != 0 && [string compare $letter "scroll"] != 0 } {
    lappend criteria "im_first_letter_default_to_a(ug.group_name)=:letter"
}
if { $include_subprojects_p == "f" } {
    lappend criteria "p.parent_id is null"
}

set order_by_clause ""
switch $order_by {
    "Type" { set order_by_clause "order by project_type" }
    "Status" { set order_by_clause "order by project_status" }
    "Project Lead" { set order_by_clause "order by upper(last_name), upper(first_names)" }
    "URL" { set order_by_clause "order by upper(url)" }
    "Name" { set order_by_clause "" }
}

set where_clause [join $criteria " and\n            "]
if { ![empty_string_p $where_clause] } {
    set where_clause " and $where_clause"
}

set sql "select ug.group_name, p.group_id,
                u.first_names, u.last_name, u.user_id,
                u.first_names || ' ' || u.last_name as lead_name, 
                im_category_from_id(p.project_type_id)  as project_type, 
                im_category_from_id(p.project_status_id)  as project_status,
                im_proj_url_from_type(p.group_id, 'website') as url
           from im_projects p, users u, user_groups ug
          where p.project_lead_id=u.user_id(+) $where_clause
            and ug.group_id=p.group_id [util_decode $order_by_clause "" "order by upper(ug.group_name)" $order_by_clause]"

if { [string compare $letter "all"] == 0 } {
    set selection "$sql $order_by_clause"
    # Set these limits to negative values to deactivate them
    set total_in_limited -1
    set how_many -1

} else {
    # Set up boundaries to limit the amount of rows we display
    if { [empty_string_p $how_many] || $how_many < 1 } {
	set how_many [ad_parameter NumberResultsPerPage intranet 50]
    }
    set end_idx [expr $start_idx + $how_many - 1]

    set limited_query [im_select_row_range $sql $start_idx $end_idx]

    # We can't get around counting in advance if we want to be able to sort inside
    # the table on the page for only those users in the query results
    set total_in_limited [db_string projects_total_in_limited \
	    "select count(*) 
               from im_projects p, user_groups ug 
              where p.group_id=ug.group_id
                and p.parent_id is null $where_clause"]

    set selection "select z.* from ($limited_query) z $order_by_clause"
}	

set results ""
set bgcolor(0) " bgcolor=\"[ad_parameter TableColorOdd Intranet white]\""
set bgcolor(1) " bgcolor=\"[ad_parameter TableColorEven Intranet white]\""
set ctr 0
set idx $start_idx
db_foreach projects_info_query $selection {
    set url [im_maybe_prepend_http $url]

    if { [empty_string_p $url] } {
	set url_string "&nbsp;"
    } else {
	set url_string "<a href=\"$url\">$url</a>"
    }

    if { [empty_string_p $merge_group_id_1] || $merge_group_id_1 == $group_id } {
	set merge_opt ""
    } else {
	set merge_group_id_2 $group_id
	set merge_opt "<font size=-1>(<a href=merge?[export_url_vars merge_group_id_1 merge_group_id_2]>merge</a>)</font>"
    }

    append results "
<tr$bgcolor([expr $ctr % 2])>
  <td valign=top>$idx</td>
  <td valign=top><a href=view?[export_url_vars group_id]>$group_name</a> $merge_opt</td>
  <td valign=top>$project_type</td>
  <td valign=top>$project_status</td>
  <td valign=top><a href=../users/view?[export_url_vars user_id]>$lead_name</a></td>
  <td valign=top>$url_string</td>
</tr>
"
    incr ctr
    if { $how_many > 0 && $ctr >= $how_many } {
	break
    }
    incr idx
}

if { $ctr == $how_many && $total_in_limited > 0 && $end_idx < $total_in_limited } {
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

db_release_unused_handles

# Note that we use a nested table because im_slider might
# return a table with a form in it (if there are too many
# options
set page_body "
<table width=100% border=0 cellpadding=0 cellspacing=0>
<tr>
  <td valign=top>
    <table border=0 cellspacing=0 cellpadding=0>
      <tr>
        <td valign=top><font size=-1>
           View:
        </font></td>
        <td valign=top><font size=-1>
           [im_slider mine_p $view_types "" [list start_idx]]
        </font></td>
      </tr>

      <tr>
        <td valign=top><font size=-1>
           Show subprojects:
        </font></td>
        <td valign=top>
          <font size=-1>
           [im_slider include_subprojects_p $subproject_types "" [list start_idx]]
        </font></td>
      </tr>

      <tr>
        <td valign=top><font size=-1>
           Project status: 
        </font></td>
        <td valign=top><font size=-1>
           [im_slider status_id $status_types "" [list start_idx]]
        </font></td>
      </tr>
      <tr>
        <td valign=top><font size=-1>
           Project type:
        </font></td>
        <td valign=top><font size=-1>
           [im_slider type_id $project_types "" [list start_idx]]
        </font></td>
      </tr>
    </table>
  </td>
  <td valign=top>
    <table border=0 cellspacing=0 cellpadding=0>
     <tr>
      <td colspan=2 valign=top align=right><font size=-1>
        <a href=../allocations/index>Allocations</a> | 
        <a href=money>Financial View</a>
      </td>
     </tr>
     <tr>
      <td valign=top><font size=-1>
        Search:
      </td>
      <td valign=top><font size=-1>
        [im_default_nav_header $previous_page $next_page "search"]
      </font></td>
     </tr>
    </table>
   </td>
</tr>
</table>

"

set column_headers [list Name Type Status "Project Lead" URL]
# Set up colspan to be the number of headers + 1 for the # column
set colspan [expr [llength $column_headers] + 1]

append page_body "
<table width=100% cellpadding=2 cellspacing=2 border=0>
<tr>
  <td align=center valign=top colspan=$colspan><font size=-1>
    [im_groups_alpha_bar [im_project_group_id] $letter "start_idx"]</font>
  </td>
</tr>
"

if { [empty_string_p $results] } {
    append page_body "<tr><td colspan=$colspan<ul><li><b> There are currently no projects matching the selected criteria</b></ul></td></tr>\n"
} else {
    set url "index?"
    set query_string [export_ns_set_vars url [list order_by]]
    if { ![empty_string_p $query_string] } {
	append url "$query_string&"
    }
    append page_body "<tr bgcolor=\"[ad_parameter TableColorHeader intranet white]\">\n  <th>#</th>\n"

    foreach col $column_headers {
	if { [string compare $order_by $col] == 0 } {
	    append page_body "  <th>$col</th>\n"
	} else {
	    append page_body "  <th><a href=\"${url}order_by=[ns_urlencode $col]\">$col</a></th>\n"
	}
    }
    append page_body "</tr>$results\n"
}

append page_body "
<tr>
  <td align=center colspan=$colspan>[im_maybe_insert_link $previous_page $next_page]</td>
</tr>
"

append page_body "</table><p><a href=ae>Add a project</a>\n"

doc_return  200 text/html [im_return_template]
