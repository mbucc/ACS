# $Id: interactions.tcl,v 3.0 2000/02/06 03:18:00 ron Exp $
set_form_variables 0
# possibly view_rep and/or view_interaction_originator and/or view_interaction_type and/or view_interaction_date

if { ![info exists view_rep] } {
    set view_rep "all"
}
if { ![info exists view_interaction_originator] } {
    set view_interaction_originator "all"
}
if { ![info exists view_interaction_type] } {
    set view_interaction_type "all"
}
if { ![info exists view_interaction_date] } {
    set view_interaction_date "all"
}
if { ![info exists order_by] } {
    set order_by "interaction_id"
}

ReturnHeaders
ns_write "[ad_admin_header "Customer Service Interactions"]

<h2>Customer Service Interactions</h2>

[ad_admin_context_bar [list "../index.tcl" "Ecommerce"] [list "index.tcl" "Customer Service Administration"] "Issues"]

<hr>

<form method=post action=interactions.tcl>
[export_form_vars view_interaction_originator view_interaction_type view_interaction_date order_by]

<table border=0 cellspacing=0 cellpadding=0 width=100%>
<tr bgcolor=ececec>
<td align=center><b>Rep</b></td>
<td align=center><b>Originator</b></td>
<td align=center><b>Type</b></td>
<td align=center><b>Date</b></td>
</tr>
<tr>
<td align=center><select name=view_rep>
<option value=\"all\">All
"

set db [ns_db gethandle]

set selection [ns_db select $db "select i.customer_service_rep as rep, u.first_names as rep_first_names, u.last_name as rep_last_name
from ec_customer_serv_interactions i, users u
where i.customer_service_rep=u.user_id
group by i.customer_service_rep, u.first_names, u.last_name
order by u.last_name, u.first_names"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { $view_rep == $rep } {
	ns_write "<option value=$rep selected>$rep_last_name, $rep_first_names\n"
    } else {
	ns_write "<option value=$rep>$rep_last_name, $rep_first_names\n"
    }
}

ns_write "</select>
<input type=submit value=\"Change\">
</td>
<td align=center>"

set interaction_originator_list [database_to_tcl_list $db "select unique interaction_originator from ec_customer_serv_interactions"]

lappend interaction_originator_list "all"

set linked_interaction_originator_list [list]

foreach interaction_originator $interaction_originator_list {
    if { $interaction_originator == $view_interaction_originator } {
	lappend linked_interaction_originator_list "<b>$interaction_originator</b>"
    } else {
	lappend linked_interaction_originator_list "<a href=\"interactions.tcl?[export_url_vars view_rep view_interaction_type view_interaction_date]&view_interaction_originator=[ns_urlencode $interaction_originator]\">$interaction_originator</a>"
    }
}

ns_write "\[ [join $linked_interaction_originator_list " | "] \]
</td>
<td align=center>
"

set interaction_type_list [database_to_tcl_list $db "select picklist_item from ec_picklist_items where picklist_name='interaction_type' order by sort_key"]

lappend interaction_type_list "all"

foreach interaction_type $interaction_type_list {
    if { $interaction_type == $view_interaction_type } {
	lappend linked_interaction_type_list "<b>$interaction_type</b>"
    } else {
	lappend linked_interaction_type_list "<a href=\"interactions.tcl?[export_url_vars view_rep view_interaction_type view_interaction_date]&view_interaction_type=[ns_urlencode $interaction_type]\">$interaction_type</a>"
    }
}

ns_write "\[ [join $linked_interaction_type_list " | "] \]
</td>
<td align=center>
"

set interaction_date_list [list [list last_24 "last 24 hrs"] [list last_week "last week"] [list last_month "last month"] [list all all]]

set linked_interaction_date_list [list]

foreach interaction_date $interaction_date_list {
    if {$view_interaction_date == [lindex $interaction_date 0]} {
	lappend linked_interaction_date_list "<b>[lindex $interaction_date 1]</b>"
    } else {
	lappend linked_interaction_date_list "<a href=\"interactions.tcl?[export_url_vars view_issue_type view_status order_by]&view_interaction_date=[lindex $interaction_date 0]\">[lindex $interaction_date 1]</a>"
    }
}


ns_write "\[ [join $linked_interaction_date_list " | "] \]

</td></tr></table>

</form>
<blockquote>
"


if { $view_rep == "all" } {
    set rep_query_bit ""
} else {
    set rep_query_bit "and i.customer_service_rep=[ns_dbquotevalue $view_rep]"
}

if { $view_interaction_originator == "all" } {
    set interaction_originator_query_bit ""
} else {
    set interaction_originator_query_bit "and i.interaction_originator='[DoubleApos $view_interaction_originator]'"
}

if { $view_interaction_type == "all" } {
    set interaction_type_query_bit ""
} else {
    set interaction_type_query_bit "and i.interaction_type='[DoubleApos $view_interaction_type]'"
}

if { $view_interaction_date == "last_24" } {
    set interaction_date_query_bit "and sysdate-i.interaction_date <= 1"
} elseif { $view_interaction_date == "last_week" } {
    set interaction_date_query_bit "and sysdate-i.interaction_date <= 7"
} elseif { $view_interaction_date == "last_month" } {
    set interaction_date_query_bit "and months_between(sysdate,i.interaction_date) <= 1"
} else {
    set interaction_date_query_bit ""
}

set link_beginning "interactions.tcl?[export_url_vars view_rep view_interaction_originator view_interaction_type view_interaction_date]"

set table_header "<table>
<tr>
<td><b><a href=\"$link_beginning&order_by=[ns_urlencode "i.interaction_id"]\">Interaction ID</a></b></td>
<td><b><a href=\"$link_beginning&order_by=[ns_urlencode "i.interaction_date"]\">Date</a></b></td>
<td><b><a href=\"$link_beginning&order_by=[ns_urlencode "rep_last_name, rep_first_names"]\">Rep</a></b></td>
<td><b><a href=\"$link_beginning&order_by=[ns_urlencode "customer_last_name, customer_first_names"]\">Customer</a></b></td>
<td><b><a href=\"$link_beginning&order_by=[ns_urlencode "i.interaction_originator"]\">Originator</a></b></td>
<td><b><a href=\"$link_beginning&order_by=[ns_urlencode "i.interaction_type"]\">Type</a></b></td>
</tr>"


set selection [ns_db select $db "select i.interaction_id, i.customer_service_rep, i.interaction_date,
to_char(i.interaction_date,'YYYY-MM-DD HH24:MI:SS') as full_interaction_date, i.interaction_originator,
i.interaction_type, i.user_identification_id, reps.first_names as rep_first_names,
reps.last_name as rep_last_name, customer_info.user_identification_id,
customer_info.user_id as customer_user_id, customer_info.first_names as customer_first_names,
customer_info.last_name as customer_last_name
from ec_customer_serv_interactions i, users reps, 
(select id.user_identification_id, id.user_id, u2.first_names, u2.last_name from ec_user_identification id, users u2 where id.user_id=u2.user_id(+)) customer_info
where i.customer_service_rep=reps.user_id(+)
and i.user_identification_id=customer_info.user_identification_id
$rep_query_bit $interaction_originator_query_bit $interaction_type_query_bit $interaction_date_query_bit
order by $order_by"]

set row_counter 0

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { $row_counter == 0 } {
	ns_write $table_header
    } elseif { $row_counter == 20 } {
	ns_write "</table>
	<p>
	$table_header
	"
	set row_counter 1
    }
    # even rows are white, odd are grey
    if { [expr floor($row_counter/2.)] == [expr $row_counter/2.] } {
	set bgcolor "white"
    } else {
	set bgcolor "ececec"
    }

    ns_write "<tr bgcolor=\"$bgcolor\"><td><a href=\"interaction.tcl?interaction_id=$interaction_id\">$interaction_id</a></td>
    <td>[ec_formatted_full_date $full_interaction_date]</td>
    "
    if { ![empty_string_p $customer_service_rep] } {
	ns_write "<td><a href=\"/admin/users/one.tcl?user_id=$customer_service_rep\">$rep_last_name, $rep_first_names</a></td>"
    } else {
	ns_write "<td>&nbsp;</td>"
    }
    if { ![empty_string_p $customer_user_id] } {
	ns_write "<td><a href=\"/admin/users/one.tcl?user_id=$customer_user_id\">$customer_last_name, $customer_first_names</a></td>"
    } else {
	ns_write "<td>unregistered user: <a href=\"user-identification.tcl?[export_url_vars user_identification_id]\">$user_identification_id</a></td>"
    }
    ns_write "<td>$interaction_originator</td>
    <td>$interaction_type</td>
    </tr>
    "
    incr row_counter
}

if { $row_counter != 0 } {
    ns_write "</table>"
} else {
    ns_write "<center>None Found</center>"
}

ns_write "
</blockquote>
[ad_admin_footer]
"
