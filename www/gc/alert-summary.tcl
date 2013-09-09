# /www/gc/alert-summary.tcl
ad_page_contract {
    Lists ads that match some alert.
    
    @author xxx
    @date unknown
    @cvs-id alert-summary.tcl,v 3.2.6.3 2000/09/22 01:37:50 kevin Exp
} {
    id_list
}
   
append html "[gc_header "Ads that matched your alert"]

<h2>Ads that matched your alert</h2>

in <a href=index>[gc_system_name]</a>

<hr>
<ul>
"

db_foreach alert_summary_query "
select classified_ad_id, users.email as poster_email, one_line, posted
from classified_ads, users
where classified_ads.user_id = users.user_id
and classified_ad_id in ([join $id_list ","])
order by classified_ad_id desc
" {
    incr counter
    append html "<li><a href=\"view-one?classified_ad_id=$classified_ad_id\">$one_line</a>"
} if_no_rows {
    append html "<li>No matching ads"
}

append html "
</ul>
[gc_footer [gc_system_owner]]"


doc_return  200 text/html $html
