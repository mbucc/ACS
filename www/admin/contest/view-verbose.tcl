# $Id: view-verbose.tcl,v 3.1 2000/03/10 20:02:04 markd Exp $
set_the_usual_form_variables

# domain_id, order_by (either "email" or "entry_date")

set db [ns_db gethandle]

set selection [ns_db 1row $db "select unique * from contest_domains where domain_id='$QQdomain_id'"]
set_variables_after_query

ReturnHeaders

ns_write "[ad_admin_header "All Entrants"]

<h2>All Entrants</h2>

[ad_admin_context_bar [list "index.tcl" "Contests"] [list "manage-domain.tcl?[export_url_vars domain_id]" "Manage Contest"] "View Entrants"]


<hr>

sorted by $order_by

<p>
"

set extra_column_info [database_to_tcl_list_list $db "select column_pretty_name, column_actual_name, column_type 
from contest_extra_columns
where domain_id = '$QQdomain_id'"]

if { $order_by == "email" } {
    set order_by_clause "order by upper(u.email)"
} elseif { $order_by == "entry_date" } {
    set order_by_clause "order by entry_date desc, upper(u.email)"
}

set selection [ns_db select $db "select et.*, u.email, u.first_names || ' ' || u.last_name as full_name
from $entrants_table_name et, users u
where et.user_id = u.user_id
$order_by_clause"]

# write the table headers

ns_write "<table width=100%>
<tr>
<TH width=30%>Name and email
"

foreach custom_column_list $extra_column_info {
    set column_pretty_name [lindex $custom_column_list 0]
    set column_actual_name [lindex $custom_column_list 1]
    set column_type [lindex $custom_column_list 2]
    ns_write "<th>$column_pretty_name"
}

ns_write "

</tr>
</table>
"

set last_entry_date ""
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { $entry_date != $last_entry_date && $order_by != "email" } {
	ns_write "<center><h4>[util_AnsiDatetoPrettyDate $entry_date]</h4></center>\n"
	set last_entry_date $entry_date
    }
    ns_write "<table width=100%>
<tr>
<TD width=30%>$full_name ($email)
</td>
"
    # we have to do the custom columns now
    foreach custom_column_list $extra_column_info {
	set column_pretty_name [lindex $custom_column_list 0]
	set column_actual_name [lindex $custom_column_list 1]
	set column_type [lindex $custom_column_list 2]
	ns_write "<td>[set $column_actual_name]"
    }
    ns_write "

</tr>
</table>"

}

ns_write "

[ad_contest_admin_footer]
"

