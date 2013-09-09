# /www/admin/referer/one-foreign-one-day.tcl
#

ad_page_contract {
    @cvs-id one-foreign-one-day.tcl,v 3.2.2.5 2000/09/22 01:35:59 kevin Exp
    @param foreign_url
    @param query_date
} {
    foreign_url:notnull
    query_date:notnull
}


set page_content "[ad_admin_header "$query_date : from $foreign_url"]

<h3>from 

<a href=\"$foreign_url\">
[ns_quotehtml $foreign_url]
</a>
</h3>

[ad_admin_context_bar [list "" "Referrals"] [list "all-from-foreign?[export_url_vars foreign_url]" "From One Foreign URL"] "Just $query_date"]

<hr>

<ul>

"



set sql "select local_url, click_count
from referer_log
where foreign_url = :foreign_url
and entry_date = :query_date
order by local_url"

db_foreach referer_by_date $sql {
    append page_content "<li>to <a href=\"$local_url\">$local_url</a> : $click_count\n"
}

append page_content "
</ul>

[ad_admin_footer]
"


doc_return  200 text/html $page_content
