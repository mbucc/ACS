<% # Supplied variables: poll_name, poll_description, choices, form_html, context_bar, poll_id %>

<html>
<head>
<title><%= $poll_name %></title>
</head>

<body bgcolor=lightblue text=purple>


<table cellspacing=10>
<tr>

<td><h2><%= $poll_name %></h2>
<%= $context_bar %>
</td>

</tr>
</table>
<hr>

<b><%= $poll_description %></b>

<center>

<form method=post action=vote.tcl>

<%= $form_html %>

<table border=2 text=white bgcolor=black>
<%= [poll_display -item_start "<tr><td>" -item_end "</tr>" -style_start "<font color=white><i>" -style_end "</i></font>"  $choices] %>
</table>

<input type=submit value=vote>

</form>

</center>

<p>

See <a href="poll-results.tcl?poll_id=<%= $poll_id %>">current results</a> of this poll.

<p>

<center>
<font size=-1>Go to the <a href="/news-templated/graphics-prefs.tcl?prefer_text_only_p=t&return_url=/poll/one-poll.tcl?poll_id=<%= $poll_id %>">plain version</a> of this page</font>
</center>

<ad-footer></ad-footer>

</body>
</html>
