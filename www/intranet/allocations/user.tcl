# $Id: user.tcl,v 3.1.4.1 2000/03/17 08:22:48 mbryzek Exp $
# File: /www/intranet/allocations/user.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
# 
# Shows all allocations for a specified user
# 

set_the_usual_form_variables 

# allocation_user_id, maybe order_by_var

set db [ns_db gethandle]

set allocated_name [database_to_tcl_string $db "select first_names || ' ' || last_name as allocated_name from users where user_id = $allocation_user_id"]



lappend where_clauses "im_projects.group_id = im_allocations.group_id"
lappend where_clauses "im_allocations.user_id = '$allocation_user_id'"
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



set sql_query  "select im_projects.group_id, im_allocations.user_id, allocation_id, 
group_name as project_name, percentage_time, start_block,
to_char(start_block, 'Mon DD, YYYY') as week_start, im_allocations.note
from im_allocations, im_projects, user_groups
where [join $where_clauses " and "]
and user_groups.group_id = im_projects.group_id
$order_by_clause"

set selection [ns_db select $db $sql_query] 

set counter 0

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    incr counter
   
    if { $order_by_last != [set $interface_separation] } {
	append allocation_list "<tr><td>&nbsp;</td></tr>"
    }

    append allocation_list "<tr><td>$week_start</td><td><a href=\"project.tcl?[export_url_vars group_id]\">$project_name</a></td><td>$percentage_time % <td><a href=add.tcl?[export_url_vars group_id user_id start_block percentage_time allocation_id allocation_user_id note]&return_url=[ns_urlencode [ns_conn url]?[ns_conn query]]>edit</a></td><td><font size=-1>$note</font></td></tr>"

    set order_by_last [set $interface_separation]

}

if { $counter == 0 } {
    append allocation_list "<br>
There are no allocations in the database right now.<p>"
}

set page_title "Allocations for $allocated_name"
set context_bar "[ad_context_bar [list "/" Home] [list "/intranet" "Intranet"] [list "index.tcl" "Project allocations"] "One employee"]"

ns_return 200 text/html " 
[ad_partner_header]

<table>
<tr><th>Week Starting</th>
<th><a href=user.tcl?[export_ns_set_vars url order_by]&order_by_var=group_id>Project</a></th>
<th><a href=user.tcl?[export_ns_set_vars url oder_by]&order_by_var=percentage_time>% of full</a></th><th>Edit</td><th>Note</td></tr>
$allocation_list
</table>
<p>
<a href=\"add.tcl?[export_url_vars allocation_user_id start_block]&return_url=[ns_urlencode [ns_conn url]?[ns_conn query]]\">Add an allocation</a></ul><p>
[ad_partner_footer]"
