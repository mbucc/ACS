# $Id: show-one-winner.tcl,v 3.1 2000/03/10 20:02:03 markd Exp $
set_the_usual_form_variables

# domain_id, user_id

# show the contest manager everything about one user_id

set db [ns_db gethandle]

set selection [ns_db 1row $db "select unique * from contest_domains where domain_id='$QQdomain_id'"]
set_variables_after_query

set selection [ns_db 1row $db "select first_names, last_name, email from users where user_id = $user_id"]
set_variables_after_query

ReturnHeaders

ns_write "[ad_admin_header "$first_names $last_name entries to $pretty_name"]

<h2>One User</h2>

[ad_admin_context_bar [list "index.tcl" "Contests"] [list "manage-domain.tcl?[export_url_vars domain_id]" "Manage Contest"] "One User"]

<hr>

<ul>
<li>user: <a href=\"/admin/users/one.tcl?[export_url_vars user_id]\">$first_names $last_name</a>
<li>email: <a href=\"mailto:$email\">$email</a>

</ul>

entries sorted by date

<p>
"

set extra_column_info [database_to_tcl_list_list $db "select column_pretty_name, column_actual_name, column_type 
from contest_extra_columns
where domain_ID = '$QQdomain_id'"]

# write the table headers

ns_write "<table>
<tr>
<TH>Entry Date
"
foreach custom_column_list $extra_column_info {
    set column_pretty_name [lindex $custom_column_list 0]
    set column_actual_name [lindex $custom_column_list 1]
    set column_type [lindex $custom_column_list 2]
    ns_write "<th>$column_pretty_name"
}


set selection [ns_db select $db "select *
from $entrants_table_name
where user_id = $user_id
order by entry_date desc"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    ns_write "<tr><td>$entry_date"
    # we have to do the custom columns now
    foreach custom_column_list $extra_column_info {
	set column_pretty_name [lindex $custom_column_list 0]
	set column_actual_name [lindex $custom_column_list 1]
	set column_type [lindex $custom_column_list 2]
	ns_write "<td>[set $column_actual_name]"
    }
    ns_write "</tr>\n"
}

ns_write "
</table>

[ad_contest_admin_footer]
"


