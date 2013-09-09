ad_page_contract {
    @cvs-id all-from-local.tcl,v 3.3.2.3 2000/09/22 01:34:29 kevin Exp
} {
    local_url
}

set html "[ad_admin_header "Clickthroughs from $local_url"]

<h3>from 

<a href=\"/$local_url\">
$local_url
</a>
</h3>

[ad_admin_context_bar [list "report" "Clickthroughs"] "All from Local URL"]

<hr>

<ul>

"



set sql "select entry_date, sum(click_count) as n_clicks
from clickthrough_log
where local_url = :local_url
group by entry_date
order by entry_date desc"

db_foreach click_list $sql -bind [ad_tcl_vars_to_ns_set local_url] {
    append html "<li>$entry_date : 
<a href=\"one-local-one-day?local_url=[ns_urlencode $local_url]&query_date=[ns_urlencode $entry_date]\">
$n_clicks</a>
"
}

append html "
</ul>
[ad_admin_footer]
"

db_release_unused_handles
doc_return 200 text/html $html

