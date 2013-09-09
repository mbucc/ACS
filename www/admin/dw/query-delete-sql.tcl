#/www/dw/query-delete-sql.tcl
ad_page_contract {
    Confirm user that the hand edit sql query about to be blank.

    @author Philip Greenspun (philg@mit.edu)
    @creation-date ?

    @param query_id an unique id identifies a query.
    @cvs-id query-delete-sql.tcl,v 1.1.2.2 2000/09/22 01:34:44 kevin Exp
} {
    {query_id:notnull,naturalnum}
}

set selection [db_0or1row dw_get_hand_edit_query {select query_name, definition_time, query_sql, first_names || ' ' || last_name as query_owner 
from queries, users
where query_id = :query_id
and query_owner = users.user_id}]

set page_content "
[ad_header "Confirm deletion of hand-edited SQL for [ns_quotehtml $query_name]"]

<h2>Confirm Deletion</h2>

of hand-edited SQL for <a href=\"query?query_id=$query_id\">[ns_quotehtml $query_name]</a> 
defined by $query_owner on [util_IllustraDatetoPrettyDate $definition_time]

<hr>

"

if [empty_string_p $query_sql] {
    append page_content "As far as we can tell, there is no hand-edited SQL for this query!\n[ad_footer]"
    
    
    doc_return  200 text/html $page_content

} 

append page_content "<blockquote>
<pre><code>
$query_sql
</code></pre>
</blockquote>

<br>
<br>

<form method=POST action=\"query-delete-sql-2\">
[export_form_vars query_id]
<center>
<input type=submit value=\"Yes I really want to delete this\">
</center>
</form>

[ad_footer]
"

db_release_unused_handles
doc_return 200 text/html $page_content





