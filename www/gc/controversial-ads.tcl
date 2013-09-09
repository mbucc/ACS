# /www/gc/controversial-ads.tcl
ad_page_contract {
    list the ads that are attracting a lot of comments

    @author philg@mit.edu
    @date 1997 or 1998
    @cvs-id controversial-ads.tcl,v 3.3.2.4 2000/09/22 01:37:51 kevin Exp
} {
    domain_id:integer
}

db_1row gc_domain_info_query [gc_query_for_domain_info $domain_id]

set simple_headline "<h2>Controversial Ads</h2>

[ad_context_bar_ws_or_index [list "index.tcl" [gc_system_name]] [list "domain-top.tcl?[export_url_vars domain_id]" $full_noun] "Controversial Ads"]
"

if ![empty_string_p [ad_parameter ControversialAdsDecoration gc]] {
    set full_headline "<table cellspacing=10><tr><td>[ad_parameter ControversialAdsDecoration gc]<td>$simple_headline</tr></table>"
} else {
    set full_headline $simple_headline
}

set whole_page "[gc_header "Controversial Ads in $domain"]

$full_headline

<hr>
<p>

<ul>
"

db_foreach controversial_ads_query "
select
  ca.classified_ad_id,
  ca.one_line,
  count(*) as comment_count
from classified_ads ca, general_comments gc
where ca.classified_ad_id = gc.on_what_id
and gc.on_which_table = 'classified_ads'
and gc.approved_p = 't'
and ca.expires > sysdate
and ca.domain_id = :domain_id
group by ca.classified_ad_id, ca.one_line
having count(*) > 1
order by count(*) desc
" -bind [ad_tcl_vars_to_ns_set domain_id ] {

    append whole_page "<li>$comment_count comments on <a href=\"view-one?classified_ad_id=$classified_ad_id\">$one_line</a>"

} if_no_rows {

    append whole_page "there aren't any controversial (2 or more comments) right now"

}

append whole_page "</ul>

[gc_footer $maintainer_email]"



doc_return  200 text/html $whole_page

