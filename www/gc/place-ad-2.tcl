# $Id: place-ad-2.tcl,v 3.1.2.1 2000/04/28 15:10:32 carsten Exp $
if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set_the_usual_form_variables

# domain_id, primary_category

#check for the user cookie
set user_id [ad_verify_and_get_user_id]

if { $user_id == 0 } {
    ad_returnredirect "/register/index.tcl?return_url=[ns_urlencode "/gc/place-ad-2.tcl?[export_url_vars domain_id primary_category]"]"
}

set db [gc_db_gethandle]

set selection [ns_db 1row $db [gc_query_for_domain_info $domain_id "insert_form_fragments, to_char(sysdate + default_expiration_days,'YYYY-MM-DD') as default_expiration_date,"]]
set_variables_after_query

set selection [ns_db 1row $db "select ad_placement_blurb from ad_categories 
where domain_id = $domain_id
and primary_category = '$QQprimary_category'"]
set_variables_after_query

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

<form method=post action=place-ad-3.tcl>
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
<td align=left>[philg_dateentrywidget expires $default_expiration_date]
"
 
if {$geocentric_p == "t"} {
    append html "<tr><th align=left  valign=top>State</th>
<td align=left>[state_widget $db "" "state"]</td></tr>
<tr><th align=left>Country</th>
<td align=left>[country_widget $db "" "country"]</td></tr>"
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
<input name=auction_p type=radio value=t CHECKED> Yes
<input name=auction_p type=radio value=f> No
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

ns_return 200 text/html $html
