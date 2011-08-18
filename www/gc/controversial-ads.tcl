# $Id: controversial-ads.tcl,v 3.1 2000/03/10 23:58:21 curtisg Exp $
# /gc/controversial-ads.tcl
#
# by philg@mit.edu in 1997 or 1998 
# 
# list the ads that are attracting a lot of comments
# 

set_the_usual_form_variables

# domain_id

set db [gc_db_gethandle]
set selection [ns_db 1row $db [gc_query_for_domain_info $domain_id]]
set_variables_after_query

set simple_headline "<h2>Controversial Ads</h2>

[ad_context_bar_ws_or_index [list "index.tcl" [gc_system_name]] [list "domain-top.tcl?[export_url_vars domain_id]" $full_noun] "Controversial Ads"]
"

if ![empty_string_p [ad_parameter ControversialAdsDecoration gc]] {
    set full_headline "<table cellspacing=10><tr><td>[ad_parameter ControversialAdsDecoration gc]<td>$simple_headline</tr></table>"
} else {
    set full_headline $simple_headline
}

set whole_page ""

append whole_page "[gc_header "Controversial Ads in $domain"]

$full_headline

<hr>
<p>

<ul>
"

set selection [ns_db select $db "select ca.classified_ad_id, ca.one_line, count(*) as comment_count
from classified_ads ca, general_comments gc
where ca.classified_ad_id = gc.on_what_id
and gc.on_which_table = 'classified_ads'
and gc.approved_p = 't'
and ca.expires > sysdate
and ca.domain_id = $domain_id
group by ca.classified_ad_id, ca.one_line
having count(*) > 1
order by count(*) desc"]

set counter 0
set items ""
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    incr counter
    append items "<li>$comment_count comments on <a href=\"view-one.tcl?classified_ad_id=$classified_ad_id\">$one_line</a>
"

}

if { $counter == 0 } {
    append whole_page "there aren't any controversial (2 or more comments) right now"
} else {
    append whole_page $items
}



append whole_page "</ul>

[gc_footer $maintainer_email]"

ns_db releasehandle $db

ns_return 200 text/html $whole_page

