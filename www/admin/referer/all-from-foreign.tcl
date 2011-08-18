# $Id: all-from-foreign.tcl,v 3.0 2000/02/06 03:27:36 ron Exp $
set_the_usual_form_variables

# foreign_url

ReturnHeaders

ns_write "[ad_admin_header "from $foreign_url"]

<h3> from 

<a href=\"$foreign_url\">
[ns_quotehtml $foreign_url]
</a>
</h3>

[ad_admin_context_bar [list "index.tcl" "Referrals"] "From One Foreign URL"]


<hr>

<ul>

"
set db [ns_db gethandle]

set selection [ns_db select $db "select entry_date, sum(click_count) as n_clicks from referer_log
where foreign_url = '$QQforeign_url'
group by entry_date
order by entry_date desc"]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    ns_write "<li>$entry_date : 
<a href=\"one-foreign-one-day.tcl?foreign_url=[ns_urlencode $foreign_url]&query_date=[ns_urlencode $entry_date]\">
$n_clicks</a>
"
}

ns_write "
</ul>

[ad_admin_footer]
"


