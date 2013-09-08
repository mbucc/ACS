# /www/admin/contest/show-one-winner.tcl
ad_page_contract {
    Displays one contest winner.

    @param domain_id which contest this is
    @param user_id the winner

    @author mbryzek@arsdigita.com
    @cvs_id show-one-winner.tcl,v 3.3.2.3 2000/09/22 01:34:37 kevin Exp
} {
    domain_id:integer
    user_id:integer
}


db_1row contest_info "select unique pretty_name, entrants_table_name from contest_domains where domain_id = :domain_id"

db_1row user_info "select first_names, last_name, email from users where user_id = :user_id"

set page_content "[ad_admin_header "$first_names $last_name entries to $pretty_name"]

<h2>One User</h2>

[ad_admin_context_bar [list "index.tcl" "Contests"] [list "manage-domain.tcl?[export_url_vars domain_id]" "Manage Contest"] "One User"]

<hr>

<ul>
<li>user: <a href=\"/admin/users/one?[export_url_vars user_id]\">$first_names $last_name</a>
<li>email: <a href=\"mailto:$email\">$email</a>

</ul>

entries sorted by date

<p>
"

set extra_column_info [db_list_of_lists extra_column_info "select column_pretty_name, column_actual_name, column_type 
from contest_extra_columns
where domain_id = :domain_id"]

# write the table headers

append page_content "<table>
<tr>
<TH>Entry Date
"
foreach custom_column_list $extra_column_info {
    set column_pretty_name [lindex $custom_column_list 0]
    set column_actual_name [lindex $custom_column_list 1]
    set column_type [lindex $custom_column_list 2]
    append page_content "<th>$column_pretty_name"
}

db_foreach entry_info "select *
from $entrants_table_name
where user_id = :user_id
order by entry_date desc" {
    append page_content "<tr><td>$entry_date"
    # we have to do the custom columns now
    foreach custom_column_list $extra_column_info {
	set column_pretty_name [lindex $custom_column_list 0]
	set column_actual_name [lindex $custom_column_list 1]
	set column_type [lindex $custom_column_list 2]
	append page_content "<td>[set $column_actual_name]"
    }
    append page_content "</tr>\n"
}

append page_content "
</table>

[ad_contest_admin_footer]
"

db_release_unused_handles

doc_return 200 text/html $page_content


