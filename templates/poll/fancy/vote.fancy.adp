<% # Supplied variables: header_image, context_bar, poll_id %>

<html>
<head>
<title>Thanks for your vote</title>
</head>

<body bgcolor=lightblue text=darkblue>


<table cellspacing=10>
<tr>

<td><%= $header_image %></td>

<td><h2>Thank you for your vote</h2>
<%= $context_bar %>
</td>

</tr>
</table>
<hr>

Thanks for your vote!  You can <a href="poll-results.tcl?poll_id=<%= $poll_id %>">check the results</a> of this poll.


<p>

<center>
<font size=-1>Go to the <a href="/news-templated/graphics-prefs.tcl?prefer_text_only_p=f&return_url=/poll/index.tcl">fancy version</a> of this page</font>
</center>

<ad-footer></ad-footer>

</body>
</html>
