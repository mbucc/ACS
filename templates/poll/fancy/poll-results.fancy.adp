<% # Supplied variables: poll_name, poll_description, values, header_image, context_bar, poll_id, total_count %>

<html>
<head>
<title>Results for <%= $poll_name %></title>
</head>


<body bgcolor=lightblue text=blue>


<table cellspacing=10>
<tr>

<td><%= $header_image %></td>

<td><h2>Results for <%= $poll_name %></h2>
<%= $context_bar %>
</td>

</tr>
</table>
<hr>

<i>
<center>

<font size=5>Total of <%= $total_count %> votes</font>
<p>

<table bgcolor=pink border=3>
<tr>
<td width=400>
<% if { $total_count > 0 } { ns_puts [poll_results -bar_color purple -display_values_p "f" -display_scale_p "f" -bar_height 30 $values] } %>
</table>
</center>

</i>

<p>

<center>
<font size=-1>Go to the <a href="/news-templated/graphics-prefs.tcl?prefer_text_only_p=t&return_url=/poll/poll-results.tcl?poll_id=<%= $poll_id %>">plain version</a> of this page</font>
</center>

<ad-footer></ad-footer>

</body>
</html>
