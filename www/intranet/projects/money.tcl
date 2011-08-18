# $Id: money.tcl,v 3.1.4.1 2000/03/17 08:23:12 mbryzek Exp $
# File: /www/intranet/projects/money.tcl
#
# Author: Feb 2000
#
# Purpose: Displays an expense report
#

set_the_usual_form_variables 0

# maybe start_block, end_block, order_by, project_status_id, project_type_id, status_all, type_all

set page_title "Expense report"
set context_bar "[ad_context_bar [list "/" Home] [list "../index.tcl" "Intranet"]  [list "index.tcl" "Projects"] "Expense report"]"

set db [ns_db gethandle]

set html [ad_partner_header]

if { ![exists_and_not_null partner_type_id] } {
    set partner_type_id ""
}

if { ![exists_and_not_null status_id] } {
    # Default status is OPEN - select the id once and memoize it
    set status_id [ad_partner_memoize_one \
	    "select project_status_id 
               from im_project_status 
              where upper(project_status) = 'OPEN'" project_status_id]
}

if {$status_id != 0} {
    lappend where_clauses "im_projects.project_status_id = $status_id"
}

if { ![exists_and_not_null type_id] } {
    set type_id 0
} elseif {$type_id != 0} {
    lappend where_clauses "im_projects.project_type_id = $type_id"
}

if { ![exists_and_not_null order_by] } {
    set order_by name
}

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

switch $order_by {
    "name" { set order_by_clause "order by upper(group_name)" }
    "project_type" { set order_by_clause "order by upper(im_project_types.project_type), upper(group_name)" }
    "status" { set order_by_clause "order by upper(im_project_status.project_status), upper(group_name)" }
    "fee_setup" { set order_by_clause "order by fee_setup, upper(group_name)" }
    "total_monthly" { set order_by_clause "order by total_monthly, upper(group_name)" }
    "total_people" { set order_by_clause "order by total_people, upper(group_name)" }
    #"rev_person" { set order_by_clause "order by rev_person, upper(name)" }
    "default" { set order_by_clause "order by upper(group_name)" }
}


#lappend where_clauses "parent is null"
#lappend where_clauses "project_type <> 'deleted'"

# NOTE: This does not take hours for subprojects into account!!
# This is just to get the demo done

# if not other wise provided, the report will be for the
# last 4 weeks

if { ![info exist end_block] } {
    set end_block [database_to_tcl_string $db "select max(start_block)
from im_start_blocks where start_block < sysdate"]
}

if { ![info exist start_block] } {
    set start_block [database_to_tcl_string $db "select to_date('$end_block','yyyy-mm-dd') - 28 from dual"]
}

set select_weeks_form "
<form action=money.tcl method=post>
Week starting:
<select name=start_block>
[im_allocation_date_optionlist $db $start_block]
</select>
through week ending:
<select name=end_block>
[im_allocation_date_optionlist $db $end_block]
</select>
<input type=submit name=submit value=Go>
</form>"

set sliders "
<table width=100% border=0>
<tr>
  <td valign=top>[ad_partner_default_font "size=-1"]
    Project status: [im_slider status_id $status_types]
    <br>Project type: [im_slider type_id $project_types]
  </font></td>
  <td align=right valign=top>[ad_partner_default_font "size=-1"]
    <a href=\"../allocations/index.tcl\">Allocations</a> | 
    <a href=\"index.tcl\">Summary View</a>
  </font></td>
</tr>
</table>
"


set num_weeks [database_to_tcl_string $db "select count(start_block) from
im_start_blocks where start_block >= '$start_block'
and start_block < '$end_block'"]

lappend where_clauses "im_projects.group_id = im_allocations.group_id(+)"


set selection [ns_db select $db "
select im_projects.group_id, group_name, 
nvl(im_projects_monthly_fee(im_projects.group_id, '$start_block', '$end_block'),0)  as total_monthly, 
nvl(im_projects_stock_fee(im_projects.group_id, '$start_block', '$end_block'),0)  as stock_fee,  
nvl(im_projects_setup_fee(im_projects.group_id,'$start_block','$end_block'),0)  as fee_setup, 
im_projects.project_type_id, im_projects.project_status_id, 
nvl(trunc(sum(percentage_time)/(100 * $num_weeks),2),0) as avg_people_week,
im_project_types.project_type, im_project_status.project_status
from im_projects, (select * from im_allocations
where (im_allocations.start_block >= '$start_block' or im_allocations.start_block is null)
and (im_allocations.start_block < '$end_block' or im_allocations.start_block is null)) im_allocations  , user_groups, im_project_status,
im_project_types
where [join $where_clauses " and " ]
and user_groups.group_id = im_projects.group_id
and im_project_status.project_status_id = im_projects.project_status_id
and im_project_types.project_type_id = im_projects.project_type_id
group by im_projects.group_id, im_allocations.group_id,  
group_name, im_projects.project_type_id, im_projects.project_status_id, 
fee_setup, fee_monthly, fee_hosting_monthly, project_type, project_status
$order_by_clause"]

append html "
$select_weeks_form

$sliders
<p>

<center>
<table width=100% cellpadding=2 cellspacing=2 border=0>
<tr>
 <td colspan=5><b>[util_AnsiDatetoPrettyDate $start_block] to [util_AnsiDatetoPrettyDate $end_block]</b></td></tr>
<tr bgcolor=[ad_parameter "TableColorHeader" "intranet"]>"

set order_by_params [list {"name" "Name"} {"project_type" "Type"} {"status" "Status"} {"fee_setup" "Total setup fees"}  {"total_monthly" "Total monthly fees"} {"stock" "Stock"} ]


foreach parameter $order_by_params {
    set pretty_order_by_current [lindex $parameter 1]
    set order_by_current [lindex $parameter 0]
    if {$order_by_current == $order_by} {
	append html "<th>$pretty_order_by_current</th>"
    } else {
	append html "<th><a href=money.tcl?order_by=$order_by_current&[export_ns_set_vars "url" "order_by"]>$pretty_order_by_current</a></th>"
    }
}

append html "<th> Average People/Week </th><th> (Rev/person)/$num_weeks weeks</th>"

set projects ""
set background_tag ""

set fee_setup_sum 0
set total_monthly_sum 0
set avg_people_week_sum 0
set rev_person_week_sum 0
set stock_fee_sum 0

set ctr 0
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { $ctr % 2 == 0 } {
	set background_tag " bgcolor = [ad_parameter "TableColorOdd" "intranet"] "
    } else {
	set background_tag " bgcolor = [ad_parameter "TableColorEven" "intranet"] "
    }
    incr ctr

    append projects "
<tr $background_tag>
 <td><A HREF=view.tcl?group_id=$group_id>$group_name</A>
 <td>$project_type
 <td>$project_status
 <td>[util_commify_number $fee_setup] &nbsp;
 <td>[util_commify_number $total_monthly] &nbsp;
 <td>[util_commify_number $stock_fee] &nbsp;
 <td>$avg_people_week &nbsp;
 <td>"
     
    if {$avg_people_week > 0} {
	set rev_person_week [expr (($fee_setup+$total_monthly + $stock_fee)/$avg_people_week)]
	 append projects "[util_commify_number $rev_person_week] &nbsp;"
     }  else {
	 set rev_person_week 0
	 append projects "NA"
     }
     append projects "</td></tr>\n"
     set fee_setup_sum [expr $fee_setup_sum + $fee_setup]
     set total_monthly_sum [expr $total_monthly_sum + $total_monthly]
     set avg_people_week_sum [expr $avg_people_week_sum + $avg_people_week]
#     set rev_person_week_sum [expr $rev_person_week_sum + $rev_person_week]
     set stock_fee_sum [expr $stock_fee_sum + $stock_fee]
}


# We don't sum the avg_people_week column because we want
# the average

#set rev_person_week_total [expr (($fee_setup_sum + $total_monthly_sum + $stock_fee_sum))/$avg_people_week_sum]

append html "$projects 
<tr>
 <td>Total
 <td>
 <td>
 <td>[util_commify_number $fee_setup_sum]
 <td>[util_commify_number $total_monthly_sum]
 <td>[util_commify_number $stock_fee_sum]
 <td>$avg_people_week_sum
</table>
</center>
<p>

"

append html [ad_partner_footer]

ns_db releasehandle $db

ns_return 200 text/html $html
