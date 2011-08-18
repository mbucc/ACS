# $Id: one-local-one-day.tcl,v 3.0 2000/02/06 03:27:51 ron Exp $
set_the_usual_form_variables

#  local_url, query_date

ReturnHeaders

ns_write "[ad_admin_header "$query_date : Referrals to $local_url"]

<h3>Referrals to <a href=\"$local_url\">$local_url</a> on $query_date
</h3>

[ad_admin_context_bar [list "index.tcl" "Referrals"] [list "all-to-local.tcl?[export_url_vars local_url]" "To One Local URL"] "Just $query_date"]

<hr>

<ul>

"
set db [ns_db gethandle]

set selection [ns_db select $db "select foreign_url, click_count
from referer_log
where local_url = '$QQlocal_url'
and entry_date = '$query_date'
order by foreign_url"]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    ns_write "<li>from <a href=\"$foreign_url\">$foreign_url</a> : $click_count\n"
}

ns_write "
</ul>

[ad_admin_footer]
"
