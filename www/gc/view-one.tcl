# /www/gc/view-one.tcl

ad_page_contract {
    this page is used to display one ad to a user; we do not sign the page
    with the maintainer email of the realm because otherwise naive users
    will send that person bids on items

    @cvs_id view-one.tcl,v 3.3.2.6 2000/09/22 01:37:57 kevin Exp
} {
    classified_ad_id:integer
}

if { [catch { db_1row gc_view_one_ad_info_get "
select  employer, salary_range, classified_ads.state, 
        classified_ads.country, domain_id, html_p, 
        days_since_posted(posted) as days_since_posted, 
        reply_to_poster_p,  one_line, posted, full_ad, 
        auction_p as ad_auction_p, users.email as poster_email, 
        users.first_names || ' ' || users.last_name as poster_name, 
        users.user_id as poster_id
from   classified_ads, users
where  classified_ads.user_id = users.user_id
and    classified_ad_id = :classified_ad_id"} errmsg] } {
    # error getting stuff from db
    doc_return  404 text/html "[gc_header "Ad missing"]

<h2>Ad missing</h2>

<p>

Perhaps:

<ul>
<li>you bookmarked an ad that you thought was interesting awhile ago
<li>someone else thought the ad was interesting and bought the item
<li>the person who posted the ad deleted it.
</ul>

Anyway, the database choked on your request and here's what it said.. 

<blockquote><code>
$errmsg
</blockquote></code>

[gc_footer [ad_system_owner]]"
     return
}

# now domain_id is set

db_1row domain_info_get [gc_query_for_domain_info $domain_id]

switch $days_since_posted { 
    0 { set age_string "today" }
    1 { set age_string "yesterday" }
    default { set age_string "$days_since_posted days ago" }
} 

# for GeoCentric classifieds, we'll want to say where this is from
if {$geocentric_p == "t"} {
    set geocentric_info "<p>\n"    
    if { ![empty_string_p $country] } {
	append geocentric_info "Country:   [ad_country_name_from_country_code $country]<br>\n"
    }
    if { ![empty_string_p $state] } {
	append geocentric_info "State:   [ad_state_name_from_usps_abbrev $state]<br>\n"
    }
} else {
    set geocentric_info ""
}

set action_items [list]

if { $ad_auction_p == "t" && $auction_p != "f" } {
    lappend action_items "<a href=\"place-bid?classified_ad_id=$classified_ad_id\">Place a bid</a> <font size=-1>(an email notice will be sent to the advertiser)</font> "
    lappend action_items "<a href=\"mailto:$poster_email\">Reply privately to $poster_email</a>"
    set sql "
    select bid, bid_time, currency, location, 
           email as bidder_email, first_names || ' ' || last_name as bidder_name, users.user_id as bidder_user_id
    from classified_auction_bids, users
    where users.user_id = classified_auction_bids.user_id
    and classified_ad_id = :classified_ad_id 
    order by bid_time desc"

    set bid_items ""
    db_foreach gc_view_one_get_bids $sql -bind [ad_tcl_vars_to_ns_set classified_ad_id] {
	append bid_items "<li>[string trim $bid] $currency bid by
<a href=\"/shared/community-member?user_id=$bidder_user_id\">$bidder_name</a>
on [util_AnsiDatetoPrettyDate $bid_time] in $location
"
    }
    if ![empty_string_p $bid_items] {
	set bid_history "<h3>Bids</h3>\n<ul>\n$bid_items\n</ul>\n"
    } else {
	set bid_history ""
    }
} else {
    # not an auction
    lappend action_items "<a href=\"mailto:$poster_email\">email $poster_email</a>"
    set bid_history ""
}

lappend action_items  "<a href=\"/shared/community-member?user_id=$poster_id\">view $poster_name's history as a community member</a>"

set n_audit_rows [db_string num_audit_rows "select count(*) as n_audit_rows from classified_ads_audit where classified_ad_id = :classified_ad_id" -bind [ad_tcl_vars_to_ns_set classified_ad_id]]

if { $n_audit_rows > 0 } {
    lappend action_items "<a href=\"view-ad-history?classified_ad_id=$classified_ad_id\">view previous versions of this ad</a>
<font size=-1 color=red>(this ad has been edited)</font>
"
}

set comment_html [ad_general_comments_list  $classified_ad_id classified_ads $one_line gc]

db_release_unused_handles

if [ad_parameter IncludeBannerIdeasP gc 0] {
    set banneridea_html "<br>
<br>

<center>
<hr width=95% size=1 noshade>
[bannerideas_random]
</center>
"
} else {
    set banneridea_html ""

}

doc_return 200 text/html "[gc_header $one_line]

<h2>$one_line</h2>

[ad_context_bar_ws_or_index [list "index.tcl" [gc_system_name]] [list "domain-top.tcl?[export_url_vars domain_id]" $full_noun] "One Ad"]

<hr>
advertised $age_string 
by
<a href=\"/shared/community-member?user_id=$poster_id\">$poster_name</a>

<blockquote>

[util_maybe_convert_to_html $full_ad $html_p]

$geocentric_info

</blockquote>

<h3>Take Action</h3>

<ul>
<li>
[join $action_items "\n<li>"]
</ul>

$comment_html

$bid_history

$banneridea_html
</body>
</html>
"

