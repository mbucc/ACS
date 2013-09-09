# /admin/links/spam-hunter.tcl

ad_page_contract {
    Find spam URLs

    @author Original Author Unknown
    @creation-date Original Date Unknown
    @cvs-id spam-hunter.tcl,v 3.3.2.5 2000/09/22 01:35:31 kevin Exp
} {
}

set page_content "[ad_admin_header "Hunting for spam"]

<h2>Hunting for spam</h2>

[ad_admin_context_bar [list "index" "Links"] "Spam Hunter"]

<hr>

<ul>

"

set link_qry "select url, count(*) as n_copies
from links
group by url
having count(*) > 2
order by count(*) desc"

db_foreach select_spam_links $link_qry {
    append page_content "<li><a href=\"$url\">$url</a> (<a href=\"spam-hunter-2?url=[ns_urlencode $url]\">$n_copies</a>)\n"
} if_no_rows {
    append page_content "<li> <i>No spam URLs found</i>"
}

db_release_unused_handles

append page_content "</ul>

[ad_admin_footer]
"

doc_return  200 text/html $page_content