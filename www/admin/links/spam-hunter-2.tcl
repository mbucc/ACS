# /admin/links/spam-hunter-2.tcl

ad_page_contract {
    Examine one potential spammer

    @param url The URL to check out

    @author Original Author Unknown
    @creation-date Original Date Unknown
    @cvs-id spam-hunter-2.tcl,v 3.2.2.4 2000/07/21 03:57:32 ron Exp
} {
    url:notnull
}

set page_content "[ad_admin_header "$url"]

<h2>$url</h2>

[ad_admin_context_bar [list "index.tcl" "Links"] [list "spam-hunter.tcl" "Spam Hunter"] "One potential spammer"]

<hr>

<ul>

"



set link_qry "select links.page_id, links.user_id, link_title, link_description, links.status, links.originating_ip, links.posting_time, sp.url_stub, sp.page_title, users.first_names, users.last_name
from links, static_pages sp, users 
where links.url = :url
and links.page_id = sp.page_id
and links.user_id = users.user_id"

db_foreach select_spam_links $link_qry {
    append page_content "<li>added by <a href=\"/admin/users/one?user_id=$user_id\">$first_names $last_name</a>
on [util_AnsiDatetoPrettyDate $posting_time]
to <a href=\"blacklist?[export_url_vars page_id url]\">$url_stub</a>
"
}

db_release_unused_handles

append page_content "</ul>

[ad_admin_footer]
"

