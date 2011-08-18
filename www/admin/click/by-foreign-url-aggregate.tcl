# $Id: by-foreign-url-aggregate.tcl,v 3.0 2000/02/06 03:14:42 ron Exp $
set_form_variables 0

#  minimum (optional)

ReturnHeaders

ns_write "[ad_admin_header "by foreign URL"]

<h2>by foreign URL</h2>

[ad_admin_context_bar [list "report.tcl" "Clickthroughs"] "By Foreign URL"]

<hr>

Note: this page may be slow to generate; it requires a tremendous
amount of chugging by the RDBMS.

<ul>

"

set db [ns_db gethandle]

if { [info exists minimum] } {
    set having_clause "\nhaving sum(click_count) >= $minimum"
} else {
    set having_clause ""
}

set selection [ns_db select $db "select local_url, foreign_url, sum(click_count) as n_clicks
from clickthrough_log
group by local_url, foreign_url $having_clause
order by foreign_url
"]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    ns_write "<li><a href=\"one-url-pair.tcl?local_url=[ns_urlencode $local_url]&foreign_url=[ns_urlencode $foreign_url]\">
$foreign_url (from $local_url) : $n_clicks
</a>
"
}

ns_write "
</ul>

[ad_admin_footer]
"
