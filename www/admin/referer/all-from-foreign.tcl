# /www/admin/referer/all-from-foreign.tcl
#

ad_page_contract {
    @param foreign_url
    @cvs-id all-from-foreign.tcl,v 3.3.2.6 2000/09/22 01:35:58 kevin Exp
} {
    foreign_url:notnull
}

set page_content "[ad_admin_header "from $foreign_url"]

<h3> from 

<a href=\"$foreign_url\">
[ns_quotehtml $foreign_url]
</a>
</h3>

[ad_admin_context_bar [list "" "Referrals"] "From One Foreign URL"]

<hr>

<ul>

"


set sql "select entry_date, sum(click_count) as n_clicks from referer_log
where foreign_url = :foreign_url
group by entry_date
order by entry_date desc"

db_foreach referer_all_from_foreign_list $sql {
    append page_content "<li>$entry_date : 
<a href=\"one-foreign-one-day?foreign_url=[ns_urlencode $foreign_url]&query_date=[ns_urlencode $entry_date]\">
$n_clicks</a>
"
}

append page_content "
</ul>

[ad_admin_footer]
"


doc_return  200 text/html $page_content
