# $Id: edit-ad.tcl,v 3.1.2.1 2000/04/28 15:09:03 carsten Exp $
# /admin/gc/edit-ad.tcl 
# a script for letting the site administrator edit a user's classified

set admin_id [ad_verify_and_get_user_id]
if { $admin_id == 0 } {
    ad_returnredirect "/register/"
    return
}

set_the_usual_form_variables

# classified_ad_id

set db [gc_db_gethandle]
if [catch { set selection [ns_db 1row $db "select ca.*, to_char(expires,'YYYY-MM-DD') as ansi_expires
from classified_ads ca
where classified_ad_id = $classified_ad_id"] } errmsg] {
    ad_return_error "Could not find Ad $classified_ad_id" "Either you are fooling around with the Location field in your browser
or my code has a serious bug.  The error message from the database was

<blockquote><code>
$errmsg
</blockquote></code>"
       return
}

# OK, we found the ad in the database if we are here...
# the variable SELECTION holds the values from the db
set_variables_after_query

# user wants to edit the ad
set selection_domain [ns_db 1row $db "select insert_form_fragments, wtb_common_p, geocentric_p, auction_p from ad_domains where domain_id = $domain_id"]
set_variables_after_query_not_selection $selection_domain

if { [string first "full_ad" $insert_form_fragments] == -1 } {
    set insert_form_fragments  [concat "<tr><th align=left>Full Ad<br>
<td><textarea name=full_ad wrap=hard rows=6 cols=50></textarea>
</tr>
<td><select name=html_p><option value=f>Plain Text<option value=t>HTML</select></td></tr>" $insert_form_fragments]

} elseif  { [string first "html_p" $insert_form_fragments] == -1 } {
    # there was full-ad in the form fragments, but there is no corresponding html_p
    append insert_form_fragments "<tr><th align=left>The full ad above is</td><td> <select name=html_p><option value=f>Plain Text<option value=t>HTML</select></td></tr>"
}

if { [string first "one_line" $insert_form_fragments] == -1 } {
    set insert_form_fragments [concat "<tr><th align=left>One Line Summary<br>
    <td><input type=text name=one_line  size=50>
    </tr>" $insert_form_fragments]
}
set raw_form "<form method=post action=edit-ad-2.tcl>
<input type=hidden name=classified_ad_id value=$classified_ad_id>

<table>
$insert_form_fragments
"


if {$geocentric_p == "t"} {
    append raw_form "<tr><th align=left  valign=top>State</th>
    <td align=left>[state_widget $db "" "state"]</td></tr>
    <tr><th align=left>Country</th>
    <td align=left>[country_widget $db "" "country"]</td></tr>"
}

if {$wtb_common_p == "t" && [string first "wanted_p" $insert_form_fragments] == -1 } {
    append raw_form "<tr><th align=left>Do you want to buy or sell?</th>
    <td align=left>
    <input name=wanted_p type=radio value=f> Sell
    <input name=wanted_p type=radio value=t> Buy
    </td></tr>"
}

if {$auction_p == "t"} {
    append raw_form "<tr><th align=left>Auction?</th>
    <td align=left>
    <input name=auction_p type=radio value=t> Yes
    <input name=auction_p type=radio value=f> No
    (this allows members to place bids) </td></tr>"
}

set selection_without_nulls [remove_nulls_from_ns_set $selection]
set final_form [bt_mergepiece $raw_form $selection_without_nulls]

if [ad_parameter EnabledP "member-value"] {
    set mistake_wad [mv_create_user_charge $user_id  $admin_id "classified_ad_mistake" $classified_ad_id [mv_rate ClassifiedAdMistakeRate]]
    set spam_wad [mv_create_user_charge $user_id $admin_id "classified_ad_spam" $classified_ad_id [mv_rate ClassifiedAdSpamRate]]
    set options [list [list "" "Don't charge user"] [list $mistake_wad "Mistake of some kind, e.g., duplicate posting"] [list $spam_wad "Spam or other serious policy violation"]]
    set member_value_section "<h3>Charge this user for his sins?</h3>
<select name=user_charge>\n"
    foreach sublist $options {
	set value [lindex $sublist 0]
	set visible_value [lindex $sublist 1]
	append member_value_section "<option value=\"[philg_quote_double_quotes $value]\">$visible_value\n"
    }
    append member_value_section "</select>
<br>
<br>
Charge Comment:  <input type=text name=charge_comment size=50>
<br>
<br>
<br>"
} else {
    set member_value_section ""
}


append html "[gc_header "Edit \"$one_line\""]

<h2>Edit \"$one_line\"</h2>

ad number $classified_ad_id in 
<a href=\"domain-top.tcl?domain_id=$domain_id\">the classifieds</a>
<hr>

$final_form
<tr><th>Expires<td>
<input name=expires type=text size=11 value=\"$ansi_expires\"> YYYY-MM-DD \[format must be exact\]
<tr><th>Category<td>
<select name=primary_category>
[db_html_select_options $db "select primary_category
from ad_categories
where domain_id = $domain_id
order by primary_category" $primary_category]
</select>
</table>
<P>

$member_value_section

<center>
<input type=submit value=\"Update Ad\">
</center>
</form>

If this ad really looks nasty, you can choose to 
<a href=\"delete-ad.tcl?[export_url_vars classified_ad_id]\">delete it instead</a>.

[ad_admin_footer]
"

ns_db releasehandle $db
ns_return 200 text/html $html
