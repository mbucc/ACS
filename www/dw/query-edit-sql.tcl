# $Id: query-edit-sql.tcl,v 3.0 2000/02/06 03:38:48 ron Exp $
set_the_usual_form_variables

# query_id

set db [ns_db gethandle]

set selection [ns_db 1row $db "select query_name, definition_time, query_sql, first_names || ' ' || last_name as query_owner 
from queries, users
where query_id = $query_id
and query_owner = users.user_id"]
set_variables_after_query

ReturnHeaders

ns_write "
[ad_header "Hand editing SQL for $query_name"]

<h2>Hand editing SQL</h2>

for <a href=\"query.tcl?query_id=$query_id\">$query_name</a> 
defined by $query_owner on [util_IllustraDatetoPrettyDate $definition_time]

<hr>

"

if [empty_string_p $query_sql] {
    # this is the first time the user has hand-edited the SQL; generate it
    set query_info [dw_build_sql $db $query_id]
    set query_sql [lindex $query_info 0]
} 

ns_write "
<form method=POST action=\"query-edit-sql-2.tcl\">
[export_form_vars query_id]
<textarea name=query_sql rows=10 cols=70>
$query_sql
</textarea>

<br>
<br>
<center>
<input type=submit value=\"Update\">
</center>
</form>
"

if { [database_to_tcl_string $db "select count(*) from query_columns where query_id = $query_id"] > 0 } {
    ns_write "<p>

If you wish to go back to the automatically generated query, you can
<a href=\"query-delete-sql.tcl?query_id=$query_id\">delete this
hand-edited SQL</a>.
"
}

ns_write "

[ad_footer]
"
