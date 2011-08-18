# $Id: alert-summary.tcl,v 3.1 2000/03/10 23:58:21 curtisg Exp $
set_form_variables

# the only interesting one is $id_list

set db [gc_db_gethandle]

set sql "select classified_ad_id, users.email as poster_email, one_line, posted
from classified_ads, users
where classified_ads.user_id = users.user_id
and classified_ad_id in ([join $id_list ","])
order by classified_ad_id desc"
   
append html "[gc_header "Ads that matched your alert"]

<h2>Ads that matched your alert</h2>

in <a href=index.tcl>[gc_system_name]</a>

<hr>
<ul>
"

set selection [ns_db select $db $sql]

set counter 0

while {[ns_db getrow $db $selection]} {
    incr counter
    set_variables_after_query
    append html "<li><a href=\"view-one.tcl?classified_ad_id=$classified_ad_id\">$one_line</a>
"
}

if { $counter == 0 } {
    append html "<li>No matching ads"
}

append html "
</ul>
[gc_footer [gc_system_owner]]"

ns_return 200 text/html $html