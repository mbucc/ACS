# $Id: entry-form.tcl,v 3.5.2.1 2000/04/28 15:09:54 carsten Exp $
if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set_the_usual_form_variables

# either domain_id or domain (for backwards compatibitility)

set db [ns_db gethandle]

if { ![info exists domain_id] && [info exists domain] } {
    set domain_id [database_to_tcl_string_or_null $db "select domain_id from contest_domains where domain='$QQdomain'"]
    set QQdomain_id [DoubleApos $domain_id]
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

set selection [ns_db 0or1row $db "select cd.*, users.email as maintainer_email
from contest_domains cd, users
where domain_id = '$QQdomain_id'
and cd.maintainer = users.user_id"]

if { $selection == "" } {
    ad_return_error "Failed to find contest" "We couldn't find a contest with a domain_id of \"$domain_id\"."
    return
}
set_variables_after_query

set the_page "[ad_header $pretty_name]

<h2>$pretty_name</h2>

in [ad_site_home_link]

<hr>

$blather



<center>
<h2>Enter Contest</h2>

<form method=POST action=\"process-entry.tcl\">
[export_form_vars domain_id]

"

set selection [ns_db select $db "select * from contest_extra_columns where domain_id = '$QQdomain_id'"]
set n_rows_found 0

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    incr n_rows_found
 
    if { $column_type == "boolean" } {
 	append table_rows "<tr><th>$column_pretty_name<td>
	<select name=$column_actual_name>
	<option value=\"t\">Yes
	<option value=\"f\">No
	</select>"
    } else {
 	append table_rows "<tr><th>$column_pretty_name<td><input type=text name=$column_actual_name size=30>"
    }
    
    if [regexp -nocase {not null} $column_extra_sql] {
	append table_rows " &nbsp; (required)"
    }
    append table_rows "</tr>\n"
}

if { $n_rows_found != 0 } {
    append the_page "<table>\n$table_rows\n</table>\n"
}

append the_page "

<p>

<center>
<input type=submit value=\"Submit Entry\">
</center>
</form>

</center>

[ad_footer $maintainer_email]
"

ns_db releasehandle $db

ns_return 200 text/html $the_page

