# $Id: money-2.tcl,v 3.1.4.1 2000/03/17 08:23:11 mbryzek Exp $
# File: /www/intranet/projects/money-2.tcl
#
# Author: Feb 2000
#
# Purpose: 
#

set_the_usual_form_variables 0

set html "
[ad_header "Expense report"]

<H2>Expense report (last 30 days)</H2>

[ad_context_bar [list "/" Home] [list "index.tcl" "Intranet"]  [list "projects.tcl" "Projects"] "Expense report"]

<HR>
"
if ![info exists status] {
    set status "open"
}

if {$status != "all"} {
    lappend where_clauses "status = '$status'"
} 

if ![info exists project_type] {
    set project_type "client"
}

if {$project_type != "all"} {
    lappend where_clauses "project_type = '$project_type'"
}

if ![info exists order_by] {
    set order_by "name"
}


switch $order_by {
    "name" { set order_by_clause "order by upper(name)" }
    "project_type" { set order_by_clause "order by project_type, upper(name)" }
    "status" { set order_by_clause "order by im_projects.status, upper(name)" }
    "fee_setup" { set order_by_clause "order by fee_setup, upper(name)" }
    "total_monthly" { set order_by_clause "order by total_monthly, upper(name)" }
    "total_people" { set order_by_clause "order by total_people, upper(name)" }
    "rev_person" { set order_by_clause "order by rev_person, upper(name)" }
    "default" { set order_by_clause "order by upper(name)" }
}

set db [ns_db gethandle]

lappend where_clauses "parent is null"

# NOTE: This does not take hours for subprojects into account!!
# This is just to get the demo done

if ![info exist start_block] {
    set start_block [database_to_tcl_string $db "select max(start_block)
from im_start_blocks where start_block < sysdate"]
}

set total_hours [database_to_tcl_string $db "select sum(hours)
from im_hours where day > sysdate - 30"]

set total_people_logging [database_to_tcl_string $db "select count(distinct(user_id))
from im_hours where day > sysdate - 30"]


# take the most recent allocation for this start_block
lappend where_clauses "im_allocations.last_modified = (select max(last_modified) from 
    im_allocations im2 
    where (im2.user_id = im_allocations.user_id or
           (im2.user_id is null 
            and im_allocations.user_id is null))
    and im2.project_id = im_allocations.project_id
    and im2.start_block = im_allocations.start_block)"

lappend where_clauses "im_projects.project_id = im_allocations.project_id"
lappend where_clauses "im_allocations.start_block = '$start_block'"

set selection [ns_db select $db "
select im_projects.project_id, name, nvl(fee_monthly,0) + nvl(fee_hosting_monthly,0) as total_monthly, fee_setup, project_type, status,sum(percentage_time)/100 as total_people, trunc((nvl(fee_monthly,0) + nvl(fee_hosting_monthly,0))/(sum(percentage_time)/100),0) as rev_person
from im_projects, im_allocations
where [join $where_clauses " and " ]
group by im_projects.project_id, im_allocations.project_id,  name, project_type, status, fee_setup, fee_monthly, fee_hosting_monthly
$order_by_clause"]


set status_params [list "open" "future" "inactive" "closed" "all"]
set type_params [list "client" "internal" "toolkit" "all"]

foreach param $status_params {
    if { $status == $param } {
	lappend status_links "<b> $param </b>"
    } else {
	lappend status_links "<a href=/intranet/projects-money.tcl?status=$param&[export_ns_set_vars "url" "status"]>$param</a>"
    }
}

foreach param $type_params {
    if { $project_type == $param } {
	lappend type_links "<b> $param </b>"
    } else {
	lappend type_links "<a href=/intranet/projects-money.tcl?project_type=$param&[export_ns_set_vars "url" "project_type"]>$param</a>"
    }
}

append html "
<table width=100%>
<tr><td>Project status: [join $status_links " | "]</td><td align=right><a href=allocation.tcl?[export_ns_set_vars]>Allocations</a> | <a href=projects.tcl?[export_ns_set_vars]>Summary view</a></td></tr>
<tr><td>Project type: [join $type_links " | "]</td><td></td></tr>
</table>
<p>
<center>
<table>
<tr bgcolor=[ad_parameter "Color2" "intranet"]>"

set order_by_params [list {"name" "Name"} {"project_type" "Type"} {"status" "Status"} {"fee_setup" "Setup fee"}  {"total_monthly" "Monthly fee"} {"total_people" "# People"} {"rev_person" "(Rev/person)/month"} ]


foreach parameter $order_by_params {
    set pretty_order_by_current [lindex $parameter 1]
    set order_by_current [lindex $parameter 0]
    if {$order_by_current == $order_by} {
	append html "<th>$pretty_order_by_current</th>"
    } else {
	append html "<th><a href=/intranet/projects-money.tcl?order_by=$order_by_current&[export_ns_set_vars "url" "order_by"]>$pretty_order_by_current</a></th>"
    }
}

set projects ""
set background_tag ""
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if [empty_string_p $background_tag] {
	set background_tag " bgcolor = [ad_parameter "Color1" "intranet"] "
    } else {
	set background_tag ""
    }

    append projects "<tr>
<td $background_tag><A HREF=project-info.tcl?project_id=$project_id>$name</A></td><td $background_tag>$project_type</td><td $background_tag>$status</td><td $background_tag>[dp_commify $fee_setup] &nbsp;</td><td $background_tag>[dp_commify $total_monthly] &nbsp;</td><td $background_tag>$total_people</td><td $background_tag>[dp_commify $rev_person]</td></tr>\n"
}


append html "$projects 
</table>
</center>
<p>

"

append html [ad_footer]

ns_db releasehandle $db

ns_return 200 text/html $html
