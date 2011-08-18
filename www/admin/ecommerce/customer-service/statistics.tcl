# $Id: statistics.tcl,v 3.0 2000/02/06 03:18:26 ron Exp $
ReturnHeaders

set page_title "Statistics and Reports"

ns_write "[ad_admin_header $page_title]
<h2>$page_title</h2>

[ad_admin_context_bar [list "../index.tcl" "Ecommerce"] [list "index.tcl" "Customer Service Administration"] $page_title]

<hr>

<h3>Issues by Issue Type</h3>
<ul>
"

set db [ns_db gethandle]

set important_issue_type_list [database_to_tcl_list $db "select picklist_item from ec_picklist_items where picklist_name='issue_type' order by sort_key"]

# for sorting
if { [llength $important_issue_type_list] > 0 } {
    set issue_type_decode ", decode(issue_type,"
    set issue_type_counter 0
    foreach issue_type $important_issue_type_list {
	append issue_type_decode "'[DoubleApos $issue_type]',$issue_type_counter,"
	incr issue_type_counter
    }
    append issue_type_decode "$issue_type_counter)"
} else {
    set issue_type_decode ""
}

set selection [ns_db select $db "select issue_type, count(*) as n_issues
from ec_customer_service_issues, ec_cs_issue_type_map
where ec_customer_service_issues.issue_id=ec_cs_issue_type_map.issue_id(+)
group by issue_type
order by decode(issue_type,null,1,0) $issue_type_decode"]

set other_issue_type_count 0
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { [lsearch $important_issue_type_list $issue_type] != -1 } {
	ns_write "<li>$issue_type: <a href=\"issues.tcl?view_issue_type=[ns_urlencode $issue_type]\">$n_issues</a>\n"
    } elseif { ![empty_string_p $issue_type] } {
	set other_issue_type_count [expr $other_issue_type_count + $n_issues]
    } else {
	if { $other_issue_type_count > 0 } {
	    ns_write "<li>all others: <a href=\"issues.tcl?view_issue_type=[ns_urlencode "all others"]\">$other_issue_type_count</a>\n"
	}
	if { $n_issues > 0 } {
	    ns_write "<li>none: <a href=\"issues.tcl?view_issue_type=uncategorized\">$n_issues</a>\n"
	}
    }
}

ns_write "</ul>

<h3>Interactions by Originator</h3>

<ul>
"

set selection [ns_db select $db "select interaction_originator, count(*) as n_interactions
from ec_customer_serv_interactions
group by interaction_originator
order by decode(interaction_originator,'customer',0,'rep',1,'automatic',2)"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    ns_write "<li>$interaction_originator: <a href=\"interactions.tcl?view_interaction_originator=[ns_urlencode $interaction_originator]\">$n_interactions</a>\n"
}

ns_write "</ul>

<h3>Interactions by Customer Service Rep</h3>

<ul>
"

set selection [ns_db select $db "select customer_service_rep, first_names, last_name, count(*) as n_interactions
from ec_customer_serv_interactions, users
where ec_customer_serv_interactions.customer_service_rep=users.user_id
group by customer_service_rep, first_names, last_name
order by count(*) desc"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    ns_write "<li><a href=\"/admin/users/one.tcl?user_id=$customer_service_rep\
\">$first_names $last_name</a>: <a href=\"interactions.tcl?view_rep=$customer_service_rep\">$n_interactions</a>\n"
}

ns_write "</ul>

<h3>Actions by Info Used</h3>

<ul>
"

set important_info_used_list [database_to_tcl_list $db "select picklist_item from ec_picklist_items where picklist_name='info_used' order by sort_key"]

# for sorting
if { [llength $important_info_used_list] > 0 } {
    set info_used_decode ", decode(info_used,"
    set info_used_counter 0
    foreach info_used $important_info_used_list {
	append info_used_decode "'[DoubleApos $info_used]',$info_used_counter,"
	incr info_used_counter
    }
    append info_used_decode "$info_used_counter)"
} else {
    set info_used_decode ""
}

set selection [ns_db select $db "select info_used, count(*) as n_actions
from ec_customer_service_actions, ec_cs_action_info_used_map
where ec_customer_service_actions.action_id=ec_cs_action_info_used_map.action_id(+)
group by info_used
order by decode(info_used,null,1,0) $info_used_decode"]

set other_info_used_count 0
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { [lsearch $important_info_used_list $info_used] != -1 } {
	ns_write "<li>$info_used: <a href=\"actions.tcl?view_info_used=[ns_urlencode $info_used]\">$n_issues</a>\n"
    } elseif { ![empty_string_p $info_used] } {
	set other_info_used_count [expr $other_info_used_count + $n_actions]
    } else {
	if { $other_info_used_count > 0 } {
	    ns_write "<li>all others: <a href=\"actions.tcl?view_info_used=[ns_urlencode "all others"]\">$other_info_used_count</a>\n"
	}
	if { $n_issues > 0 } {
	    ns_write "<li>none: <a href=\"actions.tcl?view_info_used=none\">$n_actions</a>\n"
	}
    }
}

ns_write "</ul>
[ad_admin_footer]
"
