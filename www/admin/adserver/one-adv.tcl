# $Id: one-adv.tcl,v 3.0 2000/02/06 02:46:10 ron Exp $
set_the_usual_form_variables

# adv_key

# we'll export this to adhref and adimg so that admin actions don't
# corrupt user data
set suppress_logging_p 1

ReturnHeaders

set db [ns_db gethandle]

set selection [ns_db 1row $db "select adv_key, adv_filename, local_image_p, track_clickthru_p, target_url from advs where adv_key='$QQadv_key'"]
set_variables_after_query

set raw_update_form "<FORM METHOD=POST ACTION=update-adv.tcl>
<TABLE noborder>
[export_form_vars adv_key]
<TR><td>Ad Key</td>
<td>$adv_key</td></tr>
<tr><td>Link to:</td><td><textarea name=target_url rows=4 cols=60>$target_url</textarea></td></tr>
<tr><td>Track Click Throughs:</td><td><INPUT TYPE=radio name=track_clickthru_p value=\"t\"]\">Yes <INPUT TYPE=radio name=track_clickthru_p value=\"f\"]\">No</td></tr>
<tr><td>Local Image:</td><td><INPUT TYPE=radio name=local_image_p value=\"t\"]\">Yes <INPUT TYPE=radio name=local_image_p value=\"f\"]\">No</td></tr>
<tr><td>Image File</td><td><INPUT TYPE=text name=adv_filename size=60></td></tr>
</table>
<br>
<center>
<INPUT TYPE=submit value=\"Update\">
</center>
</FORM>
"

set merged_form [bt_mergepiece $raw_update_form $selection]

ns_write "[ad_admin_header "One Ad: $adv_key"]
<h2>$adv_key</h2>

[ad_admin_context_bar [list "index.tcl" "AdServer"] "One Ad"]


<hr>

<center>
<a href=\"[ad_parameter PartialUrlStub adserver]adhref.tcl?[export_url_vars adv_key suppress_logging_p]\">"

if { $track_clickthru_p == "f" } {
    regsub -all {\$timestamp} $target_url [ns_time] cache_safe_target
    ns_write $cache_safe_target
} elseif { $local_image_p == "t" } {
    ns_write "<img border=0 src=\"[ad_parameter PartialUrlStub adserver]adimg.tcl?[export_url_vars adv_key suppress_logging_p]\">"
} else {
    ns_write "<img border=0 src=\"$adv_filename\">"
}

ns_write "</a>
</center>

"

# note that we aren't at risk of dividing by zero because 
# there won't be any rows in this table unless the ad
# has been displayed at least once
set selection [ns_db 0or1row $db "select 
  sum(display_count) as n_displays, 
  sum(click_count) as n_clicks, 
  round(100*(sum(click_count)/sum(display_count)),2) as clickthrough_percent,
  min(entry_date) as first_display, 
  max(entry_date) as last_display
from adv_log 
where adv_key = '$QQadv_key'"]
set_variables_after_query

if ![empty_string_p $first_display] {
    # we have at least one entry
    ns_write "

<h3>Summary Statistics</h3>

Between [util_AnsiDatetoPrettyDate $first_display] and [util_AnsiDatetoPrettyDate $last_display], this ad was 

<ul>
<li>displayed $n_displays times 
<li>clicked on $n_clicks times
<li>clicked through $clickthrough_percent% of the time
</ul>

<a href=\"one-adv-detailed-stats.tcl?[export_url_vars adv_key]\">detailed stats</a>

"
} else {

    ns_write "<h3>This ad has never been shown</h3>
"

}

ns_write "

<h3>Ad Parameters</h3>

"

ns_write "$merged_form
<p>

[ad_style_bodynote "If you only inserted this ad for debugging purposes, you can
take the extreme step of <a href=\"delete-adv.tcl?[export_url_vars adv_key]\">deleting this ad and its associated log entries from the database</a>."]

<p>

[ad_admin_footer]
"
