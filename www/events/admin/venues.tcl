ReturnHeaders
ns_write "[ad_header "[ad_system_name] Administration"]"

set db_pools [ns_db gethandle subquery 2]
set db [lindex $db_pools 0]
set db_sub [lindex $db_pools 1]

ns_write "
<h2>Venues</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] "Venues"]
<hr>
<form method=post action=\"venues-ae.tcl\">
<table cellpadding=5>
"

set venues_widget [events_venues_widget $db $db_sub]

if {![empty_string_p $venues_widget]} {
    ns_write "<tr><td valign=top>view/edit a venue:
    <td valign=top>$venues_widget
    <td valign=top><input type=submit value=\"View Venue\">
"
}

ns_write "
</select>
<p>
<tr><td valign=top><a href=\"venues-ae.tcl\">Add a new venue</a>
</table>
</form>
[ad_footer]"
