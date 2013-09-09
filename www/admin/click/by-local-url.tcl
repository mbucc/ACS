# www/admin/click/by-local-url.tcl

ad_page_contract {
    @cvs-id by-local-url.tcl,v 3.3.2.3 2000/09/22 01:34:30 kevin Exp
} {
    
}

set html "[ad_admin_header "Clickthroughs for [ad_system_name]"]

<h2>by local URL</h2>

[ad_admin_context_bar [list "report" "Clickthroughs"] "By Local URL"]

<hr>

<ul>
"

set sql "select distinct local_url, foreign_url 
from clickthrough_log
order by local_url
"

db_foreach url_list $sql {
    append html "<li><a href=\"one-url-pair?local_url=[ns_urlencode $local_url]&foreign_url=[ns_urlencode $foreign_url]\">
$local_url -&gt; $foreign_url
</a>
"
}

append html "
</ul>

[ad_admin_footer]
"

db_release_unused_handles
doc_return 200 text/html $html
