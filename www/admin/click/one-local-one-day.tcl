# $Id: one-local-one-day.tcl,v 3.0 2000/02/06 03:14:48 ron Exp $
set_the_usual_form_variables

#  local_url, query_date

ReturnHeaders

ns_write "[ad_admin_header "$query_date : from $local_url"]

<h3>from <a href=\"/$local_url\">$local_url</a>
</h3>

[ad_admin_context_bar [list "report.tcl" "Clickthroughs"] [list "all-from-local.tcl?[export_url_vars local_url]" "From One Local URL"] "Just $query_date"]

<hr>

<ul>

"
set db [ns_db gethandle]

set selection [ns_db select $db "select foreign_url, click_count
from clickthrough_log
where local_url = '[DoubleApos $local_url]'
and entry_date = '$query_date'
order by foreign_url"]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    ns_write "<li>to <a href=\"$foreign_url\">$foreign_url</a> : $click_count\n"
}

ns_write "
</ul>

[ad_admin_footer]
"
