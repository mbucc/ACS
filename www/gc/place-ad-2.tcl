# /www/gc/place-ad-2.tcl

ad_page_contract {
    @cvs-id place-ad-2.tcl,v 3.4.2.5 2000/09/22 01:37:54 kevin Exp
} {
    domain_id:integer
    primary_category
}

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

#check for the user cookie
set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

# This selects domain, full_noun, domain_type, auction_p, geocentric_p,
# wtb_common_p, primary_maintainer_id, maintainer_email

db_1row domain_info_get [gc_query_for_domain_info $domain_id "insert_form_fragments, to_char(sysdate + default_expiration_days,'YYYY-MM-DD') as default_expiration_date,"]

db_1row ad_info_get "
select ad_placement_blurb 
from   ad_categories 
where  domain_id = :domain_id
and    primary_category = :primary_category"


append html "[gc_header "Place $primary_category Ad"]

[ad_decorate_top "<h2>Place $primary_category Ad</h2>

[ad_context_bar_ws_or_index [list "index.tcl" [gc_system_name]] [list "domain-top.tcl?[export_url_vars domain_id]" $full_noun] "Place Ad, Step 2"]
" [ad_parameter PlaceAd2Decoration gc]]

<hr>
"

if {[string length $ad_placement_blurb] > 0} {
    append html "Hints:  $ad_placement_blurb"
}

append html "

<form method=post action=place-ad-3>
[export_form_vars domain_id primary_category]
<table>
"

if { [string first "one_line" $insert_form_fragments] == -1 } {
    append html "<tr><th align=left>One Line Summary<br>
<td><input type=text name=one_line size=50>
</tr>
"
}

if { [string first "full_ad" $insert_form_fragments] == -1 } {
    append html "<tr><th align=left>Full Ad<br>
<td><textarea name=full_ad wrap=hard rows=6 cols=50></textarea>
</tr>
<td><select name=html_p><option value=f>Plain Text<option value=t>HTML</select></td>
</tr>
"
} elseif  { [string first "html_p" $insert_form_fragments] == -1 } {
    # there was full-ad in the form fragments, but there is no corresponding html_p
    append insert_form_fragments "<tr><th align=left>The full ad above is</td><td> <select name=html_p><option value=f>Plain Text<option value=t>HTML</select></td>
</tr>
"
}

append html "$insert_form_fragments

<tr>
<th align=left>Expires</th>
<td align=left>[ad_dateentrywidget expires $default_expiration_date]
"

if {$geocentric_p == "t"} {
    append html "<tr><th align=left  valign=top>State</th>
<td align=left>[state_widget "" "state"]</td></tr>
<tr><th align=left>Country</th>
<td align=left>[country_widget "" "country"]</td></tr>"
}

if {$wtb_common_p == "t" && [string first "wanted_p" $insert_form_fragments] == -1 } {
    append html "<tr><th align=left>Do you want to buy or sell?</th>
<td align=left>
<input name=wanted_p type=radio value=f Checked> Sell
<input name=wanted_p type=radio value=t> Buy
</td></tr>"
}

if {$auction_p == "t"} {
    append html "<tr><th align=left>Auction?</th>
<td align=left>
<input name=ad_auction_p type=radio value=t CHECKED> Yes
<input name=ad_auction_p type=radio value=f> No
 (this allows members to place bids) </td></tr>"
}

append html "
<tr><th align=left>Category</th><td>$primary_category</td></tr>
</table>

<br>
<br>
<center>
<input type=submit value=\"Proceed\">
</center>
</form>

[gc_footer $maintainer_email]
"

doc_return  200 text/html $html
