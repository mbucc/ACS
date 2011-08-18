# $Id: one-adv-detailed-stats.tcl,v 3.0 2000/02/06 02:46:10 ron Exp $
set_the_usual_form_variables

# adv_key

# we'll export this to adhref and adimg so that admin actions don't
# corrupt user data
set suppress_logging_p 1

ReturnHeaders

set db [ns_db gethandle]

set selection [ns_db 1row $db "select adv_key, adv_filename, track_clickthru_p, target_url from advs where adv_key='$QQadv_key'"]
set_variables_after_query

ns_write "[ad_admin_header "Detailed Statistics: $adv_key"]
<h2>$adv_key</h2>

[ad_admin_context_bar [list "index.tcl" "AdServer"] [list "one-adv.tcl?[export_url_vars adv_key]" "One Ad"] "Detailed Statistics"]


<hr>

<center>
"

if {$track_clickthru_p == "f" } {
    ns_write $target_url
} else {
    ns_write "<a href=\"[ad_parameter PartialUrlStub adserver]adhref.tcl?[export_url_vars adv_key suppress_logging_p]\"><img border=0 src=\"[ad_parameter PartialUrlStub adserver]adimg.tcl?[export_url_vars adv_key suppress_logging_p]\"></a>

"
}
set selection [ns_db 1row $db "select sum(display_count) as n_displays, sum(click_count) as n_clicks, min(entry_date) as first_display, max(entry_date) as last_display
from adv_log 
where adv_key = '$QQadv_key'"]
set_variables_after_query

ns_write "</center>

<h3>Summary Statistics</h3>

Between [util_AnsiDatetoPrettyDate $first_display] and [util_AnsiDatetoPrettyDate $last_display], this ad was 

<ul>
<li>displayed $n_displays times 
<li>clicked on $n_clicks times
<li>clicked through [expr 100 * $n_clicks / $n_displays ]% of the time
</ul>

<h3>By Date</h3>


<table cellspacing=3>
<tr><th>Date<th>Displays<th>Clickthroughs</th><th>Clickthrough Rate</tr>

"

set selection [ns_db select $db "select *
from adv_log
where adv_key = '$QQadv_key'
order by entry_date"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    ns_write "<tr><td>[util_AnsiDatetoPrettyDate $entry_date]<td align=right>$display_count<td align=right>$click_count</td><td align=right>"
    if {$display_count > 0} {
	ns_write "[expr 100 * $click_count / $display_count ]%"
    } else {
	ns_write "0%"
    }
    ns_write "</tr>\n"
}

ns_write "

</table>
<p>

[ad_admin_footer]
"
