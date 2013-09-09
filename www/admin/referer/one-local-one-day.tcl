# /www/admin/referer/one-local-one-day.tcl
#

ad_page_contract {
    @cvs-id Id: one-local-one-day.tcl,v 3.1.2.2 2000/07/13 06:27:02 paul Exp $
    @param local_url
    @param query_date
} {
    local_url:notnull
    query_date:notnull
}


set page_content "[ad_admin_header "$query_date : Referrals to $local_url"]

<h3>Referrals to <a href=\"$local_url\">$local_url</a> on $query_date
</h3>

[ad_admin_context_bar [list "" "Referrals"] [list "all-to-local?[export_url_vars local_url]" "To One Local URL"] "Just $query_date"]

<hr>

<ul>

"


set sql "select foreign_url, click_count
from referer_log
where local_url = :local_url
and entry_date = :query_date
order by foreign_url"

db_foreach referer_by_foreign_url $sql {
    append page_content "<li>from <a href=\"$foreign_url\">$foreign_url</a> : $click_count\n"
}

append page_content "
</ul>
[ad_admin_footer]
"


doc_return  200 text/html $page_content