# add-custom-column.tcl

ad_page_contract {
    @cvs-id add-custom-column.tcl,v 3.3.2.3 2000/09/22 01:34:36 kevin Exp
} {
    domain_id:integer
}

db_1row contest_data_get "select unique * from contest_domains where domain_id=:domain_id" -bind [ad_tcl_vars_to_ns_set domain_id]

set doc_body "[ad_admin_header "Customize $pretty_name"]

<h2>Customize $pretty_name</h2>

[ad_admin_context_bar [list "index.tcl" "Contests"] [list "manage-domain.tcl?[export_url_vars domain_id]" "Manage Contest"] "Customize"]

<hr>

Customization is accomplished by adding columns to collect extra
information.  

<h3>The Default Columns (for all contests)</h3>

<table>
<tr><th>Pretty Name<th>Actual Name<th>Type<th>Extra SQL
<tr><td>Entry Date<td>entry_date<td>date<td>not null
<tr><td>User ID<td>user_id<td>integer<td>not null
</table>

<h3>Current Extra Columns</h3>

"

# entry_date and user_id are not null, but they are supplied
# by the system
set not_null_vars [list]

set sql "select * from contest_extra_columns where domain_id = :domain_id"

set n_rows_found 0

db_foreach table_rows $sql {
    incr n_rows_found
    if [regexp -nocase {not null} $column_extra_sql] {
	lappend not_null_vars $column_actual_name
    }
    append table_rows "<tr><td>$column_pretty_name<td>$column_actual_name<td>$column_type<td>$column_extra_sql</tr>\n"
}

if { $n_rows_found == 0 } {
    append doc_body "No extra columns are currently defined."
} else {
    append doc_body "<table>
<tr><th>Pretty Name<th>Actual Name<th>Type<th>Extra SQL
$table_rows
</table>
"
}

append doc_body "<h3>Define a New Custom Column</h3>

<form action=\"add-custom-column-2\" method=POST>
[export_form_vars domain_id]

Column Pretty Name:  <input name=column_pretty_name type=text size=30>

<p>

Column Actual Name:  <input name=column_actual_name type=text size=30>

<p>

Column Type:  <select name=\"column_type\">
<option value=\"boolean\">Boolean (Yes or No)
<option value=\"integer\">Integer (Whole Number)
<option value=\"number\">Number (e.g., 8.35)
<option value=\"date\">Date
<option value=\"varchar(4000)\">Text (up to 4000 characters)
</select>

<p>

If you're a database wizard, you might want to add some 
extra SQL, such as \"not null\"<br>
Extra SQL: <input type=text size=30 name=column_extra_sql>

<p>

(note that you can only truly add not null columns when the table is
empty, i.e., before anyone has entered the contest)

<p>

<input type=submit value=\"Add this new column\">

</form>

<h3>Hints for building static .html forms</h3>

You must have a hidden variable called \"domain_id\" with \"$domain_id\" as
its value.

<p>

You don't ever need to have a form input for entry_date or user_id;
these fields are filled in automatically by our entry processing
script.

<p>

Any field with a \"not null\" constraint must have a value and
therefore must be a form variable.  Currently, you have the following
not null columns:  <b>$not_null_vars</b>.

[ad_contest_admin_footer]
"

db_release_unused_handles
doc_return 200 text/html $doc_body
