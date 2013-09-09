# www/admin/click/by-foreign-url-aggregate.tcl

ad_page_contract {
    @cvs-id by-foreign-url-aggregate.tcl,v 3.2.2.3 2000/09/22 01:34:30 kevin Exp
} {
    {minimum 0}
}

set html "[ad_admin_header "by foreign URL"]

<h2>by foreign URL</h2>

[ad_admin_context_bar [list "report" "Clickthroughs"] "By Foreign URL"]

<hr>

Note: this page may be slow to generate; it requires a tremendous
amount of chugging by the RDBMS.

<ul>
"

set sql "select local_url, foreign_url, sum(click_count) as n_clicks
from clickthrough_log
group by local_url, foreign_url 
having sum(click_count) >= :minimum
order by foreign_url
"

db_foreach url_list $sql -bind [ad_tcl_vars_to_ns_set minimum] {
    append html "<li><a href=\"one-url-pair?local_url=[ns_urlencode $local_url]&foreign_url=[ns_urlencode $foreign_url]\">
$foreign_url (from $local_url) : $n_clicks
</a>
"
}

append html "
</ul>

[ad_admin_footer]
"

db_release_unused_handles
doc_return 200 text/html $html
