# $Id: all-from-local.tcl,v 3.0 2000/02/06 03:14:40 ron Exp $
set_the_usual_form_variables

#  local_url

ReturnHeaders

ns_write "[ad_admin_header "Clickthroughs from $local_url"]

<h3>from 

<a href=\"/$local_url\">
$local_url
</a>
</h3>

[ad_admin_context_bar [list "report.tcl" "Clickthroughs"] "All from Local URL"]


<hr>

<ul>

"

set db [ns_db gethandle]

set selection [ns_db select $db "select entry_date, sum(click_count) as n_clicks
from clickthrough_log
where local_url = '[DoubleApos $local_url]'
group by entry_date
order by entry_date desc"]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    ns_write "<li>$entry_date : 
<a href=\"one-local-one-day.tcl?local_url=[ns_urlencode $local_url]&query_date=[ns_urlencode $entry_date]\">
$n_clicks</a>
"
}

ns_write "
</ul>
[ad_admin_footer]
"


