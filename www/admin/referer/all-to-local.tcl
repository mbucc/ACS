# $Id: all-to-local.tcl,v 3.0 2000/02/06 03:27:37 ron Exp $
set_form_variables_string_trim_DoubleAposQQ
set_form_variables

#  local_url

ReturnHeaders

ns_write "[ad_admin_header "Referrals to $local_url"]

<h3>Referrals to 

<a href=\"$local_url\">
[ns_quotehtml $local_url]
</a>
</h3>

[ad_admin_context_bar [list "index.tcl" "Referrals"] "To One Local URL"]

<hr>

<ul>

"

set db [ns_db gethandle]

set selection [ns_db select $db "select entry_date, sum(click_count) as n_clicks
from referer_log
where local_url = '$QQlocal_url'
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


