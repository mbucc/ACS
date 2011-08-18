# $Id: project.tcl,v 3.1.4.1 2000/03/17 08:22:48 mbryzek Exp $
# File: /www/intranet/allocations/project.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Shows allocations for a specific project
# 

set_the_usual_form_variables 

# group_id, maybe order_by_var

set db [ns_db gethandle]

lappend where_clauses "users.user_id(+) = im_allocations.user_id"
lappend where_clauses "im_projects.group_id = im_allocations.group_id"
lappend where_clauses "im_allocations.group_id = '$group_id'"
lappend where_clauses "im_allocations.percentage_time > 0"


if {![info exists order_by_var] || [empty_string_p $order_by_var]}  {
    set order_by_var "start_block"
}

set order_by_clause "order by $order_by_var"
set order_by_last ""


if {$order_by_var == "group_id"} { 
   set interface_separation "project_name"
} else {
   set interface_separation "start_block"
}


# take the most recent allocation for this user for this start_block
              
set sql_query "select im_projects.group_id, users.user_id, allocation_id, 
group_name as project_name, percentage_time, start_block,
to_char(start_block, 'Mon DD, YYYY') as week_start, im_allocations.note,
first_names || ' ' || last_name as allocated_name
from im_allocations, im_projects, users, user_groups
where [join $where_clauses " and "]
and user_groups.group_id = im_projects.group_id
$order_by_clause"

set selection [ns_db select $db $sql_query] 

set counter 0

set return_url [ad_partner_url_with_query]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    incr counter
   
#    if { $order_by_last != [set $interface_separation] } {
#	append allocation_list "<tr><td>&nbsp;</td></tr>"
#    }
    append allocation_list "
<tr>
  <td>$week_start</td>
  <td><a href=\"user.tcl?allocation_user_id=$user_id\">$allocated_name</a></td>
  <td>$percentage_time % <td><a href=add.tcl?[export_url_vars group_id user_id start_block percentage_time allocation_id return_url]>edit</a></td>
  <td><font size=-1>$note</font></td>
</tr>
"

    set order_by_last [set $interface_separation]

}

if { $counter == 0 } {
    append allocation_list "<br>
    There are no allocations in the database right now.<p>"

    set project_name [database_to_tcl_string $db "select
    group_name from user_groups where group_id=$group_id"]
    
    #get the start block too!
    set start_block [database_to_tcl_string $db "select 
    get_start_week(im_projects.start_date) as start_block
    from im_projects where group_id = $group_id"]
}

set selection  [ns_db select $db "select 
first_names || ' ' || last_name as name, im_employee_info.percentage, sum(im_allocations.percentage_time) as scheduled_percentage
from im_employee_info, users, im_allocations, im_projects
where im_employee_info.user_id = users.user_id
and im_allocations.user_id = users.user_id
and [join $where_clauses " and "] 
group by im_employee_info.user_id, first_names, last_name, im_employee_info.percentage"]


set page_title "Allocations for $project_name"
set context_bar "[ad_context_bar [list "/" Home] [list "/intranet" "Intranet"] [list "index.tcl" "Project allocations"] "One project"]"

ns_return 200 text/html "
[ad_partner_header]

<table cellpadding=5>
<tr><th>Week Starting</th>
<th><a href=project.tcl?[export_ns_set_vars url order_by]&order_by_var=group_id>Employee</a></th>
<th><a href=project.tcl?[export_ns_set_vars url oder_by]&order_by_var=percentage_time>% of full</a></th><th>Edit</td><th>Note</td></tr>
$allocation_list
</table>
<p>
<a href=\"add.tcl?[export_url_vars start_block group_id]\">Add an allocation</a></ul><p>
[ad_partner_footer]"
