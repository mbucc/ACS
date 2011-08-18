# $Id: by-local-url-aggregate.tcl,v 3.0 2000/02/06 03:14:44 ron Exp $
ReturnHeaders 

ns_write  "[ad_admin_header "by local URL"]

<h2>by local URL</h2>

[ad_admin_context_bar [list "report.tcl" "Clickthroughs"] "By Local URL"]


<hr>

Note: this page may be slow to generate; it requires a tremendous
amount of chugging by the RDBMS.

<ul>

"

set db [ns_db gethandle]

set selection [ns_db select $db "select local_url, foreign_url, sum(click_count) as n_clicks
from clickthrough_log
group by local_url, foreign_url
order by local_url
"]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    ns_write "<li><a href=\"one-url-pair.tcl?local_url=[ns_urlencode $local_url]&foreign_url=[ns_urlencode $foreign_url]\">
$local_url -&gt; $foreign_url : $n_clicks
</a>
"
}

ns_write "
</ul>
[ad_admin_footer]
"
