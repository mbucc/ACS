# $Id: index-bu.tcl,v 3.1.4.1 2000/03/17 08:22:47 mbryzek Exp $

set_the_usual_form_variables 0

# maybe start_block, end_block, order_by_var, allocation_user_id

# warning
# start_block can be reassigned on this page 
#  be careful to recast start_block in your queries

set db [ns_db gethandle]

# if not other wise provided, the report will be for the
# last 4 weeks

if ![info exist end_block] {
    set end_block [database_to_tcl_string $db "select max(start_block)
from im_start_blocks where start_block < sysdate"]
}

if ![info exist start_block] {
    set start_block [database_to_tcl_string $db "select to_date('$end_block','yyyy-mm-dd') - 28 from dual"]
}


lappend where_clauses "users.user_id(+) = im_allocations.user_id"
lappend where_clauses "im_projects.group_id = im_allocations.group_id"
lappend where_clauses "im_allocations.start_block >= '$start_block'"
lappend where_clauses "im_allocations.start_block < '$end_block'"
lappend where_clauses "im_allocations.percentage_time > 0"



if {![info exists order_by_var] || [empty_string_p $order_by_var]}  {
    set order_by_var "last_name"
}

set order_by_clause "order by $order_by_var"

set order_by_last ""

if {$order_by_var == "last_name"} {
    set interface_separation "allocated_name"    
} elseif {$order_by_var == "group_id"} { 
   set interface_separation "project_name"
} else {
   set interface_separation "percentage_time"
}

set selection [ns_db select $db "select 
note, start_block as allocation_note_start_block from im_start_blocks
where start_block >= '$start_block'
and start_block < '$end_block' "]


while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    set allocation_note($allocation_note_start_block) "$note <a href=note-edit.tcl?[export_url_vars allocation_note_start_block start_block end_block]>edit</a>"
}

set selection [ns_db select $db "select 
valid_start_blocks.start_block as temp_start_block,  
sum(im_employee_percentage_time.percentage_time)/100 as percentage_time
from im_employee_percentage_time, 
 (select start_block
 from im_start_blocks 
 where start_block >= '$start_block'
 and start_block < '$end_block') valid_start_blocks 
where valid_start_blocks.start_block = im_employee_percentage_time.start_block
group by valid_start_blocks.start_block"]

#set selection [ns_db select $db "select 
#im_employee_percentage_time.start_block as temp_start_block,  sum(percentage_time)/100 as percentage_time
#from im_employee_percentage_time, im_employee_info (select start_block
#from im_start_blocks where start_block >= '$start_block'
#and start_block < '$end_block') valid_start_blocks 
#where im_employee_info.user_id = im_employee_percentage_time.user_id group by im_employee_percentage_time.start_block"]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
#    if {![exists_and_not_null percentage_time]} {
#	set percentage_time 0
#    }
    set number_developer_units_available($temp_start_block) "$percentage_time<br>"
}

set selection [ns_db select $db "select 
sum(percentage_time)/100 as percentage_time, start_block as temp_start_block
from im_allocations, im_projects, users
where [join $where_clauses " and "]
group by start_block"]


while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    set number_developer_units_scheduled($temp_start_block)  "$percentage_time"
}

set selection [ns_db select $db \
	"select start_block as temp_start_block, to_char(start_block, 'Mon DD, YYYY') as temp_pretty_start_block
           from im_start_blocks 
          where start_block >= '$start_block'
            and start_block < '$end_block'"]

set summary_text ""
set ctr 0
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    if { $ctr % 2 == 0 } {
	set background_tag " bgcolor=\"[ad_parameter TableColorOdd intranet white]\""
    } else {
	set background_tag " bgcolor=\"[ad_parameter TableColorEven intranet white]\""
    }
    incr ctr
    append summary_text "
<tr$background_tag>
  <td>$temp_pretty_start_block</td>
  <td>$allocation_note($temp_start_block)</td>
  <td>$number_developer_units_available($temp_start_block)</td>
"
    if { [info exists number_developer_units_scheduled($temp_start_block)] } {
	append summary_text "  <td>$number_developer_units_scheduled($temp_start_block)</td>"
    } else {
	append summary_text "  <td>&nbsp;</td>"
    }
    append summary_text "\n</tr>\n"
}

set sql_query  "select im_projects.group_id, users.user_id, allocation_id, 
group_name as project_name, percentage_time, start_block as temp_start_block,
to_char(start_block, 'Mon DD, YYYY') as week_start, im_allocations.note,
first_names || ' ' || last_name as allocated_name
from im_allocations, im_projects, users, user_groups
where [join $where_clauses " and "]
and user_groups.group_id = im_projects.group_id
$order_by_clause"

set selection [ns_db select $db $sql_query] 

set counter 0

set allocation_list ""
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    incr counter
   
    if { $order_by_last != [set $interface_separation] } {
	append allocation_list "<tr><td>&nbsp;</td></tr>"
    }
    append allocation_list "<tr><td>$week_start</td><td><a href=\"project.tcl?[export_url_vars group_id]\">$project_name</a></td><td><a href=user.tcl?allocation_user_id=$user_id>$allocated_name</a></td><td>$percentage_time % <td><a href=add.tcl?[export_url_vars group_id user_id  percentage_time allocation_id]&start_block=$temp_start_block>edit</a></td><td><font size=-1>$note</font></td></tr>"

    set order_by_last [set $interface_separation]

}

set num_weeks [database_to_tcl_string $db "select count(start_block) from
im_start_blocks where start_block >= '$start_block'
and start_block < '$end_block'"]

set selection  [ns_db select $db "select 
first_names || ' ' || last_name as name, 
available_view.percentage_time as percentage,
scheduled_view.percentage_time as scheduled_percentage
from im_employee_info, users,
(select sum(percentage_time) as percentage_time, user_id 
from im_employee_percentage_time
where start_block >= '$start_block'
and start_block < '$end_block'
group by user_id) available_view,
(select sum(percentage_time) as percentage_time, user_id 
from im_allocations
where start_block >= '$start_block'
and start_block < '$end_block'
group by user_id) scheduled_view
where im_employee_info.user_id = users.user_id
and im_employee_info.user_id = available_view.user_id
and im_employee_info.user_id = scheduled_view.user_id"]

set over_allocated ""
set under_allocated ""

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    if {$scheduled_percentage < "$percentage"} {
	append under_allocated "<li>$name (Scheduled $scheduled_percentage% of $percentage%  available)<br>"
    }
    if {$scheduled_percentage > $percentage} {
	append over_allocated "<li>$name (Scheduled $scheduled_percentage% of $percentage% available)<br>"
    }
}

if { [empty_string_p $over_allocated] } {
    set over_allocated "  <li><i>none</i>"
} 
if { [empty_string_p $under_allocated] } {
    set under_allocated "  <li><i>none</i>"
} 


set page_title "Allocations (Time stamp)"
set context_bar "[ad_context_bar [list "/" Home] [list "/intranet" "Intranet"] "Project allocations"]"

set page_body "
<table width=100% cellpadding=5><tr><td>
<form action=index.tcl method=post>
Week starting:
<select name=start_block>
[im_allocation_date_optionlist $db $start_block]
</select>
through week ending:
<select name=end_block>
[im_allocation_date_optionlist $db $end_block]
</select>

<input type=submit name=submit value=Go>
</form>
</td><td align=right valign=top>[ad_partner_default_font "size=-1"]
<a href=../projects/index.tcl?[export_ns_set_vars]>Summary view</a> |
<a href=../projects/money.tcl?[export_ns_set_vars]>Financial view</a> 
</font></table>
<p>

<h3>Summary</h3>
<table cellpadding=2 cellspacing=2 border=1>
<tr bgcolor=\"[ad_parameter TableColorHeader intranet white]\">
  <th>Week of</th>
  <th>Note</th>
  <th>Available staff</th>
  <th>Scheduled staff</th>
</tr>
$summary_text
</table>

<p>
"

if { [empty_string_p $allocation_list] } {
    append page_body "<b>There are no allocations in the database right now.</b><p>\n"
} else {
    append page_body "

<table cellpadding=5>
<tr><th>Week Starting</th>
<th><a href=index.tcl?[export_ns_set_vars url order_by]&order_by_var=group_id>Project</a></th>
<th><a href=index.tcl?[export_ns_set_vars url order_by]&order_by_var=last_name>Employee</a></th>
<th><a href=index.tcl?[export_ns_set_vars url oder_by]&order_by_var=percentage_time>% of full</a></th><th>Edit</td><th>Note</td></tr>
$allocation_list
</table>
"
}

append page_body "
<h3>Allocation problems</h3>
[ad_partner_default_font]<b>Under allocated</b></font><br>
<ul>
$under_allocated
</ul>
[ad_partner_default_font]<b>Over allocated</b></font><br>
<ul>
$over_allocated
</ul>

<p>
<a href=\"add.tcl?[export_url_vars start_block]\">Add an allocation</a></ul><p>

"

ns_db releasehandle $db

ns_return 200 text/html [ad_partner_return_template]
