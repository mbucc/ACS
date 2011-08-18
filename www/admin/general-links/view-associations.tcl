# File: /admin/general-links/view-associations.tcl
# Date: 2/01/2000
# Author: tzumainn@arsdigita.com 
#
# Purpose: 
# view all associations of a specific link
#
# $Id: view-associations.tcl,v 3.1 2000/03/09 00:21:42 tzumainn Exp $
#--------------------------------------------------------

ad_page_variables {link_id {approval_dimension_value "unexamined_only"}}

set return_url "view-associations.tcl?link_id=$link_id&approval_dimension_value=$approval_dimension_value"

if { $approval_dimension_value == "all" } {
    set approval_widget "all | <a href=\"view-associations.tcl?link_id=$link_id&approval_dimension_value=unexamined_only\">unexamined only</a> | <a href=\"view-associations.tcl?link_id=$link_id&approval_dimension_value=approved_only\">approved only</a> | <a href=\"view-associations.tcl?link_id=$link_id&approval_dimension_value=unapproved_only\">unapproved only</a>"
} elseif { $approval_dimension_value == "approved_only" } {
    # we're currently looking at approved
    set approval_widget "<a href=\"view-associations.tcl?link_id=$link_id&approval_dimension_value=all\">all</a> | <a href=\"view-associations.tcl?link_id=$link_id&approval_dimension_value=unexamined_only\">unexamined only</a> | approved only | <a href=\"view-associations.tcl?link_id=$link_id&approval_dimension_value=unapproved_only\">unapproved only</a>"
} elseif { $approval_dimension_value == "unapproved_only" } {
    # we're currently looking at unapproved
    set approval_widget "<a href=\"view-associations.tcl?link_id=$link_id&approval_dimension_value=all\">all</a> | <a href=\"view-associations.tcl?link_id=$link_id&approval_dimension_value=unexamined_only\">unexamined only</a> | <a href=\"view-associations.tcl?link_id=$link_id&approval_dimension_value=approved_only\">approved only</a> | unapproved only"
} else {
    # we're currently looking at unexamined
    set approval_widget "<a href=\"view-associations.tcl?link_id=$link_id&approval_dimension_value=all\">all</a> | unexamined only | <a href=\"view-associations.tcl?link_id=$link_id&approval_dimension_value=approved_only\">approved only</a> | <a href=\"view-associations.tcl?link_id=$link_id&approval_dimension_value=unapproved_only\">unapproved only</a>"
}

if { $approval_dimension_value == "all" } {
    set where_clause_for_approval ""
} elseif { $approval_dimension_value == "approved_only" } {
    set where_clause_for_approval "and approved_p = 't'"
} elseif { $approval_dimension_value == "unapproved_only" } {
    set where_clause_for_approval "and approved_p = 'f'"
} else {
    set where_clause_for_approval "and approved_p is NULL"
}

set db [ns_db gethandle]

set selection [ns_db 0or1row $db "select url, link_title from general_links where link_id = $link_id"]

page_validation {
    if {[empty_string_p $selection]} {
	error "Link $link_id is not a valid link id."
    }
}

set_variables_after_query

ad_return_top_of_page "[ad_header "Link Associations for $url"]

<h2>Link Associations for $url</h2>

[ad_admin_context_bar [list "" "General Links"] "Link Associations for $url"]

<hr>

<p>
"

set selection [ns_db select $db "select
 map_id,
 on_which_table,
 on_what_id,
 one_line_item_desc,
 slm.creation_time,
 approved_p,
 first_names || ' ' || last_name as linker_name
from site_wide_link_map slm, users
where slm.link_id = $link_id
and slm.creation_user = users.user_id
$where_clause_for_approval
order by on_which_table, slm.creation_time desc"]

set assoc_html ""
set n_assoc 0

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    incr n_assoc
   
    append assoc_html "<table width=90%>
    <tr><td><blockquote>
    <b>$on_which_table</b>: $on_what_id - $one_line_item_desc
    <p>-- Posted by $linker_name on [util_AnsiDatetoPrettyDate creation_time]
    </blockquote>
    </td>
    <td align=right>
    "

    if { $approved_p == "f" } {
	append assoc_html "<a href=\"toggle-assoc-approved-p.tcl?map_id=$map_id&approved_p=t&return_url=[ns_urlencode $return_url]\">approve</a>\n<br>\n"
    } elseif { $approved_p == "t" } {
	append assoc_html "<a href=\"toggle-assoc-approved-p.tcl?map_id=$map_id&approved_p=f&return_url=[ns_urlencode $return_url]\">reject</a>\n<br>\n"
    } else {
	append assoc_html "<a href=\"toggle-assoc-approved-p.tcl?map_id=$map_id&approved_p=t&return_url=[ns_urlencode $return_url]\">approve</a>\n<br>\n <a href=\"toggle-assoc-approved-p.tcl?map_id=$map_id&approved_p=f&return_url=[ns_urlencode $return_url]\">reject</a>\n<br>\n"
    }

    append assoc_html "
    <a href=\"delete-assoc.tcl?map_id=$map_id&return_url=[ns_urlencode $return_url]\">delete association</a>
    </td>
    </table>\n
    "
}

if { $n_assoc == 0 } {
    set assoc_html "<ul><li>no associations</ul>"
}

ns_write "
<ul>
<li>Link associations for <a href=\"$url\">$link_title</a> ($url):
<p><table width=100%><tr><td align=left valign=top>
<td align=left valign=top>$approval_widget
</table>
<p>$assoc_html
</ul>

[ad_admin_footer]
"

