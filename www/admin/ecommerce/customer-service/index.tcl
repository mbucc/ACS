# $Id: index.tcl,v 3.0 2000/02/06 03:17:47 ron Exp $
ReturnHeaders
ns_write "[ad_admin_header "Customer Service Administration"]

<h2>Customer Service Administration</h2>

[ad_admin_context_bar [list "../index.tcl" "Ecommerce"] "Customer Service Administration"]

<hr>

<ul>
<li>Insert <a href=\"interaction-add.tcl\">New Interaction</a>
</ul>

<h3>Customer Service Issues</h3>

<ul>
<b><li>uncategorized</b> :
"

set db [ns_db gethandle]

set num_open_issues [database_to_tcl_string $db "select count(*) 
from ec_customer_service_issues issues, ec_user_identification id
where issues.user_identification_id = id.user_identification_id
and close_date is NULL 
and deleted_p = 'f'
and 0 = (select count(*) from ec_cs_issue_type_map map where map.issue_id=issues.issue_id)"]

ns_write "<a href=\"issues.tcl\">open</a> <font size=-1>($num_open_issues)</font> | 
<a href=\"issues.tcl?view_status=closed\">closed</a>

<p>
"

# only want to show issue types in the issue type widget, and then clump all others under
# "other"
set issue_type_list [database_to_tcl_list $db "select picklist_item from ec_picklist_items where picklist_name='issue_type' order by sort_key"]


foreach issue_type $issue_type_list {

    set num_open_issues [database_to_tcl_string $db "select count(*) 
from ec_customer_service_issues issues, ec_user_identification id
where issues.user_identification_id = id.user_identification_id
and close_date is NULL 
and deleted_p = 'f'
and 1 <= (select count(*) from ec_cs_issue_type_map map where map.issue_id=issues.issue_id and map.issue_type='[DoubleApos $issue_type]')"]


ns_write "<b><li>$issue_type</b> : 

<a href=\"issues.tcl?view_issue_type=[ns_urlencode $issue_type]\">open</a> <font size=-1>($num_open_issues)</font> | <a href=\"issues.tcl?view_issue_type=[ns_urlencode $issue_type]&view_status=closed\">closed</a>

<p>
"

}

# same query for issues that aren't in issue_type_list

if { [llength $issue_type_list] > 0 } {
    # taking advantage of the fact that tcl lists are just strings
    set safe_issue_type_list [DoubleApos $issue_type_list]
    set last_bit_of_query "and 1 <= (select count(*) from ec_cs_issue_type_map map where map.issue_id=issues.issue_id and map.issue_type not in ('[join $safe_issue_type_list "', '"]'))"
} else {
    set last_bit_of_query "and 1 <= (select count(*) from ec_cs_issue_type_map map where map.issue_id=issues.issue_id)"
}

set num_open_issues [database_to_tcl_string $db "select count(*) 
from ec_customer_service_issues issues, ec_user_identification id
where issues.user_identification_id = id.user_identification_id
and close_date is NULL 
and deleted_p = 'f'
$last_bit_of_query"]


ns_write "<b><li>all others</b> :
<a href=\"issues.tcl?view_issue_type=[ns_urlencode "all others"]\">open</a> <font size=-1>($num_open_issues)</font> |
<a href=\"issues.tcl?view_issue_type=[ns_urlencode "all others"]&view_status=closed\">closed</a>
</ul>
<p>
"

if { [llength $issue_type_list] == 0 } {
    ns_write "<b>If you want to see issues separated out by commonly used issue types, then add those issue types to the issue type picklist below in Picklist Management.</b>" 
}

ns_write "</ul>
<p>

<h3>Customers</h3>

<ul>
<FORM METHOD=get ACTION=/admin/users/search.tcl>
<input type=hidden name=target value=\"one.tcl\">
<li>Quick search for registered users: <input type=text size=15 name=keyword>
</FORM>

<p>

<form method=post action=user-identification-search.tcl>
<li>Quick search for unregistered users with a customer service history:
<input type=text size=15 name=keyword>
</form>

<p>

<form method=post action=customer-search.tcl>
<li>Customers who have spent over
<input type=text size=5 name=amount>
([ad_parameter Currency ecommerce])
in the last <input type=text size=2 name=days> days
<input type=submit value=\"Go\">
</form>
</ul>

<h3>Administrative Actions</h3>

<ul>
<li><a href=\"spam.tcl\">Spam Users</a>
<li><a href=\"picklists.tcl\">Picklist Management</a>
<li><a href=\"canned-responses.tcl\">Canned Responses</a>

<p>

<li><a href=\"statistics.tcl\">Statistics and Reports</a>
</ul>

[ad_admin_footer]
"

