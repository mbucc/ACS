# /www/gc/domain-top.tcl 

ad_page_contract {
    the top-level page for one section within classifieds
 
    @param domain_id

    @author philg@mit.edu
    @author teadams@mit.edu
    @creation-date 1995 
    @cvs-id domain-top.tcl,v 3.4.2.7 2000/09/22 01:37:52 kevin Exp
} {
    domain_id:integer
}

# parameters

set how_many_recent_ads_to_display [ad_parameter HowManyRecentAdsToDisplay gc 5]

set active_p [db_string domain "select lower(active_p) from ad_domains where domain_id = :domain_id" -bind [ad_tcl_vars_to_ns_set domain_id]]

if { $active_p  != "t"  } {
    # it is declared to be inactive
    ad_return_complaint 1 "This is no longer active"
    return
}

if { [db_0or1row domain_info_get [gc_query_for_domain_info $domain_id "blurb, blurb_bottom,"]]==0 } {
    ad_return_complaint 1 "<li>Couldn't find a classifieds ad domain of \"$domain\" on this server.  Perhaps you got a mangled link?"
    return
}

set simple_headline "<h2>$full_noun</h2>

[ad_context_bar_ws_or_index [list "index.tcl" [gc_system_name]] $full_noun]
"

if ![empty_string_p [ad_parameter DomainTopDecorationTop gc]] {
    set full_headline "<table cellspacing=10><tr><td>[ad_parameter DomainTopDecorationTop gc]<td>$simple_headline</tr></table>"
} else {
    set full_headline $simple_headline
}

set whole_page ""

append whole_page "[gc_header "$full_noun"]

$full_headline

<hr>

\[ <a href=\"place-ad?domain_id=$domain_id\">Place An Ad</a> |

<a href=\"edit-ad?domain_id=$domain_id\">Edit Old Ad</a> |

<a href=\"add-alert?domain_id=$domain_id\">Add/Edit Alert</a>

"

if { $auction_p == "t" } {
    append whole_page "|\n\n<a href=\"auction-hot?domain_id=$domain_id\">Hot Auctions</a>\n\n"
}

if [ad_parameter SolicitCommentsP gc 0] {
    # there might be comments
    append whole_page "|\n\n<a href=\"controversial-ads?domain_id=$domain_id\">Controversies</a>\n\n"
}

if ![empty_string_p [ad_second_to_last_visit_ut]] {
    append whole_page "|\n\n<a href=\"new-since-last-visit?domain_id=$domain_id\">New Since Last Visit</a>\n\n"
}

append whole_page "

\]


<p>

$blurb
<p>

<h3>Recent Ads</h3>

<ul>

"

# rownum won't work to limit rows for this (because of the ORDER BY clause) 

set sql "select classified_ad_id,one_line
from classified_ads
where domain_id = :domain_id
and (sysdate <= expires or expires is null)
order by classified_ad_id desc"

set counter 0
set items ""
db_foreach ads_list $sql -bind [ad_tcl_vars_to_ns_set domain_id] {
    append items "<li><a href=\"view-one?classified_ad_id=$classified_ad_id\">
$one_line
</a>
"
    incr counter
    if { $counter ==  $how_many_recent_ads_to_display } {
	break
    }
}

append whole_page "
$items
<p><li><a href=\"domain-all?domain_id=$domain_id&by_category_p=f&wtb_p=f\">All Ads Chronologically</a>
"

if { [info exists wtb_common_p] && $wtb_common_p == "t" } {
    append whole_page "
(<a href=\"domain-all?domain_id=$domain_id&by_category_p=f&wtb_p=t\">including wanted to buy</a>)"
}

append whole_page "

</ul>

"

if { $counter >=  $how_many_recent_ads_to_display } {
    # there are more ads than shown above
    append whole_page "

<h3>Ads by Category</h3>

<ul>"

    # this call to util_memoize is safe because the domain has been validated
    # in the database management system
    append whole_page [util_memoize "gc_categories_for_one_domain {$domain_id}" 600]

    append whole_page "<p><li><a href=\"domain-all?domain_id=$domain_id&by_category_p=t&wtb_p=t\">All Ads by Category</a>

</ul>"

    if {$geocentric_p == "t"} {
	append whole_page "<h3>Ads by Location</h3>
    <form action=view-location method=post>
    By Country<br>
    [country_widget "" "country"]<br>
    By State<br>
    [state_widget "" "state"]<br>
    <input type=hidden name=domain_id value=\"$domain_id\">
    <input type=submit name=submit value=\"List by Location\">
    </form>
	"

    }
}

if [gc_search_active_p] {
    append whole_page "
<form method=post action=search method=get>
<input type=hidden name=domain_id value=\"$domain_id\">
or ask for a full text search:  <input type=text size=30 name=query_string>
<input type=submit name=submit value=\"Search\">
</form>"
}

append whole_page "
$blurb_bottom

[gc_footer "$maintainer_email"]"

doc_return  200 text/html $whole_page

