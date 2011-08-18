# $Id: place-bid.tcl,v 3.2.2.1 2000/04/28 15:10:32 carsten Exp $
set_form_variables

# classified_ad_id is the key


# check for the user cookie

set user_id [ad_get_user_id]

if {$user_id == 0} {
    ad_returnredirect /register/index.tcl?return_url=[ns_urlencode /gc/place-bid.tcl?classified_ad_id=$classified_ad_id]
}


set db [gc_db_gethandle]

if [catch {set selection [ns_db 1row $db "select domain_id, days_since_posted(posted) as days_since_posted, users.email as poster_email, users.first_names || ' ' || users.last_name as poster_name, users.user_id as poster_id, html_p, one_line, posted, full_ad, auction_p, users.user_id as poster_user_id
from classified_ads, users
where users.user_id=classified_ads.user_id
and classified_ad_id = $classified_ad_id"]} errmsg] {
    # error getting stuff from db
    ad_return_error "Ad missing" "from <a href=\"index.tcl\">[gc_system_name]</a>

<p>

My theory is that the following occurred:

<ul>
<li>you bookmarked an ad that you thought was interesting awhile ago
<li>someone else thought the ad was interesting and bought the item
<li>the person who posted the ad deleted it.
</ul>

Anyway, the database choked on your request and here's what it said.. 

<blockquote><code>
$errmsg
</blockquote></code>"
    return

}

set_variables_after_query

# now domain_id is set, so we'll get info for a backlink


set selection [ns_db 1row $db [gc_query_for_domain_info $domain_id]]
set_variables_after_query

set bid_id [database_to_tcl_string $db "select classified_auction_bid_id_seq.nextval from dual"]

switch $days_since_posted { 
    0 { set age_string "today" }
    1 { set age_string "yesterday" }
    default { set age_string "$days_since_posted days ago" }
} 

ReturnHeaders

ns_write "[gc_header "Bid on $one_line"]

<h2>Place a Bid</h2>

on <a href=\"view-one.tcl?[export_url_vars classified_ad_id]\">$one_line</a>

<hr>

advertised $age_string by <a href=\"/shared/community-member.tcl?user_id=$poster_user_id\">$poster_name</a> 

<p>

<form method=post action=place-bid-2.tcl>
[export_form_vars bid_id classified_ad_id]
<table>
<tr><th>Your Bid<td><input type=text name=bid size=10>
<tr><th>Currency<td><input type=text name=currency value=\"US dollars\" size=10>
<tr><th>Your Location<td><input type=text name=location size=20> (e.g., \"New York City\")

</table>

<br>

<center>
<input type=submit value=\"Place Bid\">
</center>
</form>

<h3>Just to remind you...</h3>

<blockquote>

[util_maybe_convert_to_html $full_ad $html_p]

</blockquote>

[gc_footer $maintainer_email]
"

