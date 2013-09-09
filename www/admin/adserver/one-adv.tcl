# /www/admin/adserver/one-adv.tcl

ad_page_contract {
    @param adv_key:notnull
    @author modified 07/13/200 by mchu@arsdigita.com
    @cvs-id one-adv.tcl,v 3.2.2.6 2000/11/20 23:55:19 ron Exp
} {
    adv_key:notnull
}

# we'll export this to adhref and adimg so that admin actions don't
# corrupt user data

set suppress_logging_p 1

set selection [ns_set create]

db_1row adv_info_query "
select adv_key, 
       adv_filename, 
       local_image_p, 
       track_clickthru_p, 
       target_url 
from   advs 
where  adv_key = :adv_key" -column_set selection 

set target_url        [ns_set get $selection target_url]
set track_clickthru_p [ns_set get $selection track_clickthru_p]
set local_image_p     [ns_set get $selection local_image_p]
set adv_filename      [ns_set get $selection adv_filename]

set raw_update_form "
<FORM METHOD=POST ACTION=update-adv>
<TABLE noborder>
[export_form_vars adv_key]
<TR>
<td>Ad Key</td>
<td>$adv_key</td>
</tr>

<tr>
<td>Link to:</td>
<td><textarea name=target_url rows=4 cols=60>$target_url</textarea></td>
</tr>

<tr>
<td>Track Click Throughs:</td>
<td><INPUT TYPE=radio name=track_clickthru_p value=\"t\"]\">Yes 
    <INPUT TYPE=radio name=track_clickthru_p value=\"f\"]\">No
</td>
</tr>

<tr>
<td>Local Image:</td>
<td><INPUT TYPE=radio name=local_image_p value=\"t\"]\">Yes 
    <INPUT TYPE=radio name=local_image_p value=\"f\"]\">No
</td>
</tr>

<tr>
<td>Image File</td>
<td><INPUT TYPE=text name=adv_filename size=60>
</td>
</tr>

<tr><td></td><td><INPUT TYPE=submit value=Update></td></tr>

</table>
</FORM>
"

set merged_form [bt_mergepiece $raw_update_form $selection]

set page_content "
[ad_admin_header "One Ad: $adv_key"]
<h2>$adv_key</h2>

[ad_admin_context_bar [list "" "AdServer"] "One Ad"]

<hr>

<center>
"

set adv_stub  "[ad_parameter PartialUrlStub adserver]"
set adv_image "<img border=0 src=${adv_stub}adimg?[export_url_vars adv_key suppress_logging_p]>"

if { $track_clickthru_p == "f" } {
    regsub -all {\$timestamp} $target_url [ns_time] cache_safe_target
    append page_content "
    <a href=\"$cache_safe_target\">
    $adv_image
    </a>"
} else {
    append page_content "
    <a href=\"${adv_stub}adhref?[export_url_vars adv_key suppress_logging_p]\">
    $adv_image
    </a>"
}

append page_content "</center>"

# note that we aren't at risk of dividing by zero because 
# there won't be any rows in this table unless the ad
# has been displayed at least once

set display_count [db_string adv_display_count "select count(*) from adv_log where adv_key=:adv_key"]

if { $display_count > 0 } {
    db_0or1row adv_info_select "
       select sum (display_count) as n_displays, 
              sum (click_count) as n_clicks, 
              round (100 * (sum (click_count) /sum (display_count)), 2) as clickthrough_percent, 
              min (entry_date) as first_display, 
              max (entry_date) as last_display 
       from   adv_log 
       where  adv_key = :adv_key"
    # we have at least one entry
    append page_content "
    <h3>Summary Statistics</h3>
	   
    Between [util_AnsiDatetoPrettyDate $first_display] and [util_AnsiDatetoPrettyDate $last_display], this ad was 
	   
    <ul>
    <li>displayed $n_displays times  
    <li>clicked on $n_clicks times
    <li>clicked through $clickthrough_percent% of the time
    </ul>
    
    <a href=\"one-adv-detailed-stats?[export_url_vars adv_key]\">detailed stats</a>
    "   
} else {
    append page_content "<h3>This ad has never been shown</h3>"
}

append page_content "

<h3>Ad Parameters</h3>

"

append page_content "$merged_form
<p>

<h3>Extreme actions:</h3>
<ul>
<li><a href=\"delete-adv?[export_url_vars adv_key]\">
delete this ad and its associated log entries from the database</a>
</ul>

<p>

[ad_admin_footer]
"

doc_return 200 text/html $page_content
