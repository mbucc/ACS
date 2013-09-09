# /www/admin/searches/by-word-aggregate.tcl
ad_page_contract {
    @cvs-id by-word-aggregate.tcl,v 3.1.6.5 2000/09/22 01:36:04 kevin Exp
} {
    minimum:naturalnum,optional
}

if { ![info exists minimum] || [empty_string_p $minimum] } {
    set minimum 10 
}

set page_content  "[ad_admin_header "User Searches - word summary"]

<h2>User Searches - word summary</h2>

[ad_admin_context_bar [list "index.tcl" "User Searches"] "Summary by Word"]

<hr>

Query strings we've seen a minimum of $minimum times:

<ul>
"

set sql "select query_string, count(query_string) as num_searches
from query_strings 
group by query_string
having count(query_string) >= :minimum
order by count(query_string) desc"

db_foreach with_minimum_search_select $sql {
    append page_content "<li><a href=\"by-word?query_string=[ns_urlencode $query_string]\">$query_string: $num_searches</a>"
}

db_release_unused_handles

append page_content "</ul>
[ad_admin_footer]
"

doc_return  200 text/html $page_content

