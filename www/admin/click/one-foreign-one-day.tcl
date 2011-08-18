# $Id: one-foreign-one-day.tcl,v 3.0 2000/02/06 03:14:47 ron Exp $
set_the_usual_form_variables

# foreign_url, query_date

ReturnHeaders

ns_write "[ad_admin_header "$query_date : -&gt; $foreign_url"]

<h3> -&gt; 

<a href=\"$foreign_url\">
$foreign_url
</a>
</h3>

[ad_admin_context_bar [list "report.tcl" "Clickthroughs"] [list "all-to-foreign.tcl?[export_url_vars foreign_url]" "To One Foreign URL"] "Just $query_date"]

<hr>

<ul>

"

set db [ns_db gethandle]

set selection [ns_db select $db "select local_url, click_count
from clickthrough_log
where foreign_url = '[DoubleApos $foreign_url]'
and entry_date = '$query_date'
order by local_url"]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    ns_write "<li>from <a href=\"/$local_url\">$local_url</a> : $click_count\n"
}

ns_write "
</ul>

[ad_admin_footer]
"
