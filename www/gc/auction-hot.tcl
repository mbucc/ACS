# /gc/auction-hot.tcl

ad_page_contract {
    list the ads that are attracting a lot of auction bids.

    @author philg@mit.edu
    @date 1997 or 1998
    @cvs-id auction-hot.tcl,v 3.4.2.5 2000/09/22 01:37:51 kevin Exp
} {
    domain_id:integer
}

db_1row gc_domain_info_query [gc_query_for_domain_info $domain_id]

set simple_headline "<h2>Hot Auctions</h2>

[ad_context_bar_ws_or_index [list "index.tcl" [gc_system_name]] [list "domain-top.tcl?[export_url_vars domain_id]" $full_noun] "Active Auctions"]
"

if ![empty_string_p [ad_parameter HotAuctionsDecoration gc]] {
    set full_headline "<table cellspacing=10><tr><td>[ad_parameter HotAuctionsDecoration gc]<td>$simple_headline</tr></table>"
} else {
    set full_headline $simple_headline
}

set whole_page ""

append whole_page "[gc_header "Hot Auctions in $domain"]

$full_headline

<hr>
<p>

<ul>
"

set hot_threshold [ad_parameter HotAuctionThreshold gc 1]

db_foreach hot_auction_query {
    select ca.classified_ad_id, 
           ca.one_line,
           count(*) as bid_count
    from classified_ads ca, classified_auction_bids cab
    where ca.classified_ad_id = cab.classified_ad_id
    and ca.expires > sysdate
    and ca.domain_id = :domain_id
    group by ca.classified_ad_id, ca.one_line
    having count(*) > :hot_threshold
    and max(bid_time) > sysdate - 7
    order by count(*) desc
} {
    append whole_page "<li>$bid_count bids on
    <a href=\"view-one?classified_ad_id=$classified_ad_id\">$one_line</a>"
} if_no_rows {
    append whole_page "there aren't any actively auctioned ($hot_threshold or more bids) items right now"
}

append whole_page "</ul>

[gc_footer $maintainer_email]"


doc_return  200 text/html $whole_page

