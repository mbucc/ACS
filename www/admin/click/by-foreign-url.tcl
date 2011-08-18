# $Id: by-foreign-url.tcl,v 3.0 2000/02/06 03:14:43 ron Exp $
ReturnHeaders

ns_write "[ad_admin_header "Clickthroughs by foreign URL from [ad_system_name]"]


<h2>by foreign URL</h2>

[ad_admin_context_bar [list "report.tcl" "Clickthroughs"] "By Foreign URL"]

<hr>

<ul>

"

set db [ns_db gethandle]

set selection [ns_db select $db "select distinct local_url, foreign_url 
from clickthrough_log
order by foreign_url"]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    ns_write "<li><a href=\"one-url-pair.tcl?local_url=[ns_urlencode $local_url]&foreign_url=[ns_urlencode $foreign_url]\">
$foreign_url (from $local_url)
</a>
"
}

ns_write "
</ul>

[ad_admin_footer]
"
