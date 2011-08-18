# $Id: query-delete-sql.tcl,v 3.0 2000/02/06 03:38:45 ron Exp $
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
[ad_header "Confirm deletion of hand-edited SQL for $query_name"]

<h2>Confirm Deletion</h2>

of hand-edited SQL for <a href=\"query.tcl?query_id=$query_id\">$query_name</a> 
defined by $query_owner on [util_IllustraDatetoPrettyDate $definition_time]

<hr>

"

if [empty_string_p $query_sql] {
    ns_write "Hey, as far as we can tell, there is no hand-edited SQL for this query!\n[ad_footer]"
    return 
} 

ns_write "<blockquote>
<pre><code>
$query_sql
</code></pre>
</blockquote>

<br>
<br>

<form method=POST action=\"query-delete-sql-2.tcl\">
[export_form_vars query_id]
<center>
<input type=submit value=\"Yes I really want to delete this\">
</center>
</form>

[ad_footer]
"
