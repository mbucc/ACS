# www/admin/click/one-foreign-one-day.tcl

ad_page_contract {
    @cvs-id one-foreign-one-day.tcl,v 3.1.2.3 2000/09/22 01:34:30 kevin Exp
} {
    foreign_url
    query_date  
}

set html "[ad_admin_header "$query_date : -&gt; $foreign_url"]

<h3> -&gt; 

<a href=\"$foreign_url\">
$foreign_url
</a>
</h3>

[ad_admin_context_bar [list "report" "Clickthroughs"] [list "all-to-foreign.tcl?[export_url_vars foreign_url]" "To One Foreign URL"] "Just $query_date"]

<hr>

<ul>
"

set sql "select local_url, click_count
from clickthrough_log
where foreign_url = :foreign_url
and entry_date = :query_date
order by local_url"

db_foreach url_list $sql -bind [ad_tcl_vars_to_ns_set foreign_url query_date] {
    append html "<li>from <a href=\"/$local_url\">$local_url</a> : $click_count\n"
}

append html "
</ul>

[ad_admin_footer]
"

db_release_unused_handles
doc_return 200 text/html $html
