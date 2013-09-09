# /www/admin/referer/all-to-local.tcl
#

ad_page_contract {
    Shows all the referers to a given url.
    @param local_url
    @cvs-id all-to-local.tcl,v 3.3.2.5 2000/09/22 01:35:58 kevin Exp
} {
    local_url:notnull
}


set page_content "[ad_admin_header "Referrals to $local_url"]

<h3>Referrals to 

<a href=\"$local_url\">
[ns_quotehtml $local_url]
</a>
</h3>

[ad_admin_context_bar [list "" "Referrals"] "To One Local URL"]

<hr>

<ul>

"

set sql "select entry_date, sum(click_count) as n_clicks
from referer_log
where local_url = :local_url
group by entry_date
order by entry_date desc"


db_foreach referer_list $sql {
    append page_content "<li>$entry_date : 
<a href=\"one-local-one-day?local_url=[ns_urlencode $local_url]&query_date=[ns_urlencode $entry_date]\">
$n_clicks</a>
"
}

append page_content "
</ul>
[ad_admin_footer]
"


doc_return  200 text/html $page_content

