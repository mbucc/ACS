# /www/admin/searches/word-list.tcl
ad_page_contract {
    @cvs-id word-list.tcl,v 3.2.2.6 2000/09/22 01:36:05 kevin Exp
} {
}

set page_content "[ad_admin_header "User Searches - words"]

<h2>User Searches - words</h2>

recorded by the <a href=\"index\">search tracking</a> of <a href=\"/admin/index\">[ad_system_name] administration</a>

<hr>

<h3>Searched words</h3>
<ul>"

set sql "select distinct query_string
from query_strings
order by lower(query_string) asc"

db_foreach query_strings_select $sql {
    append page_content "<li><a href=\"by-word?query_string=[ns_urlencode $query_string]\">$query_string</a>"
}

db_release_unused_handles

append page_content "</ul>
[ad_admin_footer]
"

doc_return  200 text/html $page_content
