# www/admin/click/one-local-one-day.tcl

ad_page_contract {
    @cvs-id one-local-one-day.tcl,v 3.1.2.3 2000/09/22 01:34:30 kevin Exp
} {
    local_url
    query_date   
}

set html "[ad_admin_header "$query_date : from $local_url"]

<h3>from <a href=\"/$local_url\">$local_url</a>
</h3>

[ad_admin_context_bar [list "report" "Clickthroughs"] [list "all-from-local.tcl?[export_url_vars local_url]" "From One Local URL"] "Just $query_date"]

<hr>

<ul>
"

set sql "select foreign_url, click_count
from clickthrough_log
where local_url = :local_url
and entry_date = :query_date
order by foreign_url"

db_foreach url_list $sql -bind [ad_tcl_vars_to_ns_set local_url query_date] {
    append html "<li>to <a href=\"$foreign_url\">$foreign_url</a> : $click_count\n"
}

append html "
</ul>

[ad_admin_footer]
"

db_release_unused_handles
doc_return 200 text/html $html
