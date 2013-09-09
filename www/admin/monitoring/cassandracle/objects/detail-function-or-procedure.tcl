# /admin/monitoring/cassandracle/objects/detail-function-or-procedure.tcl

ad_page_contract {
    Display source code for a PL/SQL function or procedure.
    @cvs-id detail-function-or-procedure.tcl,v 3.2.2.6 2000/09/22 01:35:36 kevin Exp
} {
    object_name
    owner
}

set page_name $object_name

set the_query "select text
from DBA_SOURCE
where name = :object_name and owner = :owner
order by line"

set description [join [db_list mon_plsql_source $the_query]]


set page_content "
[ad_admin_header $page_name]

<h2>$page_name</h2>

[ad_admin_context_bar  [list "/admin/monitoring" "Monitoring"] [list "/admin/monitoring/cassandracle" "Cassandracle"] [list \"/admin/monitoring/cassandracle/users/\" "Users"] [list "/admin/monitoring/cassandracle/users/user-owned-objects" "Objects" ] [list "/admin/monitoring/cassandracle/users/one-user-specific-objects?owner=ACS&object_type=FUNCTION" "Functions"] "One"]

<hr>
<p>
<blockquote><pre>$description</pre></blockquote>
<p>
The SQL:
<pre>
$the_query
</pre>
[ad_admin_footer]
"


doc_return  200 text/html $page_content
