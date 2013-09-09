ad_page_contract {
    @cvs-id all-to-foreign.tcl,v 3.3.2.4 2000/09/22 01:34:30 kevin Exp
} {
    foreign_url
}

append html "[ad_admin_header "&gt; $foreign_url"]

<h3> -&gt; 

<a href=\"$foreign_url\">
$foreign_url
</a>
</h3>

[ad_admin_context_bar [list "report" "Clickthroughs"] "All to Foreign URL"]

<hr>

<ul>

"


set sql "select entry_date, sum(click_count) as n_clicks from clickthrough_log
where foreign_url = :foreign_url
group by entry_date
order by entry_date desc"

db_foreach click_list $sql -bind [ad_tcl_vars_to_ns_set foreign_url] {
    append html "<li>$entry_date : 
<a href=\"one-foreign-one-day?foreign_url=[ns_urlencode $foreign_url]&query_date=[ns_urlencode $entry_date]\">
$n_clicks</a>
"
}

append html "
</ul>

[ad_admin_footer]
"

db_release_unused_handles
doc_return 200 text/html $html
