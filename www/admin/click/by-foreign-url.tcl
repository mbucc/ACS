# www/admin/click/by-foreign-url.tcl

ad_page_contract {
    @cvs-id by-foreign-url.tcl,v 3.3.2.3 2000/09/22 01:34:30 kevin Exp
} {
}

set doc_body "[ad_admin_header "Clickthroughs by foreign URL from [ad_system_name]"]

<h2>by foreign URL</h2>

[ad_admin_context_bar [list "report" "Clickthroughs"] "By Foreign URL"]

<hr>

<ul>

"



set sql "select distinct local_url, foreign_url 
from clickthrough_log
order by foreign_url"

db_foreach url_list $sql {
    append doc_body "<li><a href=\"one-url-pair?local_url=[ns_urlencode $local_url]&foreign_url=[ns_urlencode $foreign_url]\">
$foreign_url (from $local_url)
</a>
"
}

append doc_body "
</ul>

[ad_admin_footer]
"

db_release_unused_handles
doc_return 200 text/html $doc_body

