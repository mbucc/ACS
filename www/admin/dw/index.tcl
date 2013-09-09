#/www/dw/index.tcl

ad_page_contract {
    List all predefine queries and option to create new query.

    @author Philip Greenspun (philg@mit.edu)
    @creation-date ?
    @cvs-id index.tcl,v 1.1.2.2 2000/09/22 01:34:43 kevin Exp

} {
}

set page_content "
[ad_header "Query [dw_system_name]"]

<h2>Query</h2>

<a href=/>[dw_system_name]</a>

<hr>

<ul>
<li><a href=\"query-new\">define a new query</a>

<p>
"

db_foreach dw_get_query_name "select query_id, query_name from queries order by definition_time desc" {
    append page_content "<li><a href=\"query?query_id=$query_id\">[ns_quotehtml $query_name]</a>\n"
}

append page_content "

</ul>

[ad_footer]
"


doc_return  200 text/html $page_content
