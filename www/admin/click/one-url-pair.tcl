# www/admin/click/one-url-pair.tcl

ad_page_contract {
    @cvs-id one-url-pair.tcl,v 3.3.2.3 2000/09/22 01:34:31 kevin Exp
} {
    local_url
    foreign_url    
}

set html "[ad_admin_header "$local_url -&gt; $foreign_url</title>"]

<h3>

<a href=\"/$local_url\">
$local_url
</a>

 -&gt;

<a href=\"$foreign_url\">
$foreign_url
</a>
</h3>

[ad_admin_context_bar [list "report" "Clickthroughs"] "One URL Pair"]

<hr>

<ul>
"

set sql "select entry_date, click_count
from clickthrough_log
where local_url = :local_url
and foreign_url = :foreign_url
order by entry_date desc"

db_foreach url_list $sql -bind [ad_tcl_vars_to_ns_set local_url foreign_url] {
    append html "<li>$entry_date : $click_count\n"
}

append html "
</ul>

<h4>Still not satisfied?</h4>

[ad_system_name] adminstration can build you a report of
<ul>

<li><a href=\"all-to-foreign?foreign_url=[ns_urlencode $foreign_url]\">
all clickthroughs from [ad_system_name] to $foreign_url</a>
(lumping together all the referring pages)
<li>
<a href=\"all-from-local?local_url=[ns_urlencode $local_url]\">
all clickthroughs from $local_url</a>
(lumping together all the foreign URLs)
</ul>

[ad_admin_footer]
"

db_release_unused_handles
doc_return 200 text/html $html
