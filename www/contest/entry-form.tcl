# /www/contest/entry-form.tcl
ad_page_contract {
    The contest entry form.

    @param domain_id which contest this is
    @param domain which contest this is (for backwards compatibility)

    @author mbryzek@arsdigita.com
    @cvs_id entry-form.tcl,v 3.7.6.6 2000/09/22 01:37:18 kevin Exp
} {
    {domain_id:integer ""}
    {domain ""}
}


if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

if { [empty_string_p domain_id] && ![empty_string_p domain] } {
    set domain_id [db_string -default "" domain_id_from_domain "select domain_id from contest_domains where domain=:domain"]
}

# test for integrity

if { [empty_string_p $domain_id] } {
    ad_return_error "Serious problem with the previous form" "Either the previous form didn't say which of the contests in [ad_site_home_link]
or the domain_id variable was set wrong or something."
    return
}


set user_id [ad_get_user_id]

if {$user_id == 0} {
   ad_returnredirect "/register.tcl?return_url=[ns_urlencode "/contest/entry-form.tcl?[export_url_vars domain_id domain]"]"
    return
}


# get out variables to create entry form

if {![db_0or1row contest_info "select cd.*, users.email as maintainer_email
from contest_domains cd, users
where domain_id = :domain_id
and cd.maintainer = users.user_id"]} {
    ad_return_error "Failed to find contest" "We couldn't find a contest with a domain_id of \"$domain_id\"."
    return
}


set page_content "[ad_header $pretty_name]

<h2>$pretty_name</h2>

in [ad_site_home_link]

<hr>

$blather



<center>
<h2>Enter Contest</h2>

<form method=get action=\"process-entry\">
[export_form_vars domain_id]

"

set n_rows_found 0
set custom_vars [list]
db_foreach extra_columns "select * from contest_extra_columns where domain_id = :domain_id" {
    incr n_rows_found
    if { $column_type == "boolean" } {
 	append table_rows "<tr><th>$column_pretty_name<td>
	<select name=$column_actual_name>
	<option value=\"t\">Yes
	<option value=\"f\">No
	</select>"
    } else {
 	append table_rows "<tr><th>$column_pretty_name<td><input type=text name=custom.$column_actual_name size=30>"
	lappend custom_vars $column_actual_name
    }
    
    if [regexp -nocase {not null} $column_extra_sql] {
	append table_rows " &nbsp; (required)"
    }
    append table_rows "</tr>\n"
}

if { $n_rows_found != 0 } {
    append page_content "<table>\n$table_rows\n</table>\n"
}

append page_content "

<p>

<center>
<input type=submit value=\"Submit Entry\">
</center>
[export_form_vars custom_vars]
</form>

</center>

[ad_footer $maintainer_email]
"



doc_return  200 text/html $page_content

