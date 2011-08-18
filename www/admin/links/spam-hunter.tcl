# $Id: spam-hunter.tcl,v 3.1 2000/02/29 04:39:24 jsc Exp $
# find spam URLs

ReturnHeaders

ns_write "[ad_admin_header "Hunting for spam"]

<h2>Hunting for spam</h2>

[ad_admin_context_bar [list "index.tcl" "Links"] "Spam Hunter"]

<hr>

<ul>

"

set db [ns_db gethandle]

set selection [ns_db select $db "select url, count(*) as n_copies
from links
group by url
having count(*) > 2
order by count(*) desc"]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    ns_write "<li><a href=\"$url\">$url</a> (<a href=\"spam-hunter-2.tcl?url=[ns_urlencode $url]\">$n_copies</a>)\n"
}


ns_write "</ul>

[ad_admin_footer]
"
