# /www/admin/contest/view-verbose.tcl
ad_page_contract {
    Displays all the contest entries (in detail).

    @param domain_id which contest this is
    @param order_by

    @author mbryzek@arsdigita.com
    @author Mark Dettinger <dettinger@arsdigita.com>
    @author Sarah Arnold <sarnold@arsdigita.com>

    @cvs_id view-verbose.tcl,v 3.2.2.8 2000/09/22 01:34:37 kevin Exp
} {
    domain_id:integer
    order_by
}


db_1row contest_info "select unique entrants_table_name from contest_domains where domain_id = :domain_id"

set page_content "[ad_admin_header "All Entrants"]

<h2>All Entrants</h2>

[ad_admin_context_bar [list "index.tcl" "Contests"] [list "manage-domain.tcl?[export_url_vars domain_id]" "Manage Contest"] "View Entrants"]

<hr>

sorted by $order_by

<p>
<table border=1>
<tr bgcolor=\"#ccff66\">
<th>Name and email</th>
"

set custom_column_size 1

set extra_column_info [db_list_of_lists extra_column_info "select column_pretty_name, column_actual_name, column_type 
from contest_extra_columns
where domain_id = :domain_id"]

foreach custom_column_list $extra_column_info {
    set column_pretty_name [fst $custom_column_list]
    set column_actual_name [snd $custom_column_list]
    set column_type        [thd $custom_column_list]
    if {[empty_string_p $column_pretty_name]} {
        # Give the browser something for the empty space!
        set column_pretty_name "&nbsp;"
    }
    append page_content "<th>$column_pretty_name</th>"
    incr custom_column_size
}

append page_content </tr>

if { $order_by == "email" } {
    set order_by_clause "order by upper(u.email)"
} elseif { $order_by == "entry_date" } {
    set order_by_clause "order by entry_date desc, upper(u.email)"
}

# write the table rows

set last_entry_date ""

db_foreach entry_info "select et.*, u.email, u.first_names || ' ' || u.last_name as full_name
from $entrants_table_name et, users u
where et.user_id = u.user_id
$order_by_clause" {

    if { $entry_date != $last_entry_date && $order_by != "email" } {
        append page_content "<tr bgcolor=\"#ffff99\"><td align=left colspan=$custom_column_size><b>[util_AnsiDatetoPrettyDate $entry_date]</b></td></tr>"
        set last_entry_date $entry_date
    }

    # write the row
    append page_content "<tr>\n  <td valign=top>$full_name<br>($email)</td>\n"

    # we have to do the custom columns now
    foreach custom_column_list $extra_column_info {
	set column_pretty_name [lindex $custom_column_list 0]
	set column_actual_name [lindex $custom_column_list 1]
	set column_type        [lindex $custom_column_list 2]
	set column_value [set $column_actual_name]        
        if { [empty_string_p $column_value] } {
            # give the browser something for the empty space!
            set column_value "&nbsp;"
        } elseif { [string equal $column_actual_name url] } {
            set column_value "<a href=\"$column_value\">$column_value</a>"
        }
        append page_content "  <td valign=top>$column_value</td>\n"
    }
    append page_content "</tr>\n"
}

append page_content "
</table>
[ad_contest_admin_footer]
"



doc_return  200 text/html $page_content

