# $Id: index.tcl,v 3.0 2000/02/06 03:28:18 ron Exp $
ReturnHeaders
ns_write "[ad_admin_header "User Searches"]

<h2>User Searches</h2>

[ad_admin_context_bar "User Searches"]

<hr>

<ul>
<li><form action=recent.tcl method=post>
last
<select name=num_days>
[ad_generic_optionlist [day_list] [day_list] 7]
</select> days <input type=submit name=submit value=\"Go\">
<li> <a href=\"word-list.tcl\">by word</a>
<li> <a href=\"location-list.tcl\">by location</a>
<li> <a href=\"results-none.tcl\">with 0 results</a>
<p>
</ul>

<h3>Expensive Queries (may take a long time) </h3>
<ul>
<li> <a href=\"by-word-aggregate.tcl\">by word</a> (summary report)
</ul>
[ad_admin_footer]
"
