# $Id: view-ad-history.tcl,v 3.1 2000/03/10 23:58:32 curtisg Exp $
# this page is used to show a deleted ad (for community member history)
# or an old version of a current ad (so that people can see if someone
# is playing stupid games by adding REDUCED to an ad

set_form_variables

# classified_ad_id is the key

append html "[gc_header "Ad $classified_ad_id"]

<h2>Ad $classified_ad_id</h2>

[ad_context_bar_ws_or_index [list "index.tcl" [gc_system_name]] "Ad History"]

<hr>

<ul>

"

set db [gc_db_gethandle]

set selection [ns_db 0or1row $db "select one_line, full_ad, html_p, last_modified 
from classified_ads
where classified_ad_id = $classified_ad_id"]

if { $selection != "" } {
    set_variables_after_query
    append html "<li>Current (last modified $last_modified): $one_line
<blockquote>
[util_maybe_convert_to_html $full_ad $html_p]
</blockquote>
"
}

set selection [ns_db select $db "select domain_id, days_since_posted(posted) as days_since_posted, one_line, posted, full_ad, auction_p, html_p, caa.last_modified,
u.user_id as poster_user_id, u.email as poster_email, u.first_names || ' ' || u.last_name as poster_name
from classified_ads_audit caa, users u
where classified_ad_id = $classified_ad_id
and caa.user_id = u.user_id(+)
order by caa.last_modified desc"]

set history_items ""
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append history_items "<li>$last_modified: $one_line
<blockquote>
[util_maybe_convert_to_html $full_ad $html_p]
</blockquote>
"
}

if ![empty_string_p $poster_user_id] {
    set user_credit "Originally posted $posted 
by <a href=\"/shared/community-member.tcl?user_id=$poster_user_id\">$poster_email</a> ($poster_name)
"
} else {
    set user_credit ""
}

append html "$history_items
</ul>

$user_credit 

<p>

<blockquote><i>
Note: this page shows the full ad history, including all intermediate
edits before the ad was deleted.  This can help community members
judge whether an advertiser is engaging in deceptive practices such as 
claiming that an item has been reduced in price.
</i></blockquote>

</body>
</html>
"

ns_return 200 text/html $html
