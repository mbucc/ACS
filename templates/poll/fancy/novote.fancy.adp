<% # Supplied variables: header_image, context_bar, poll_id %>

<html>
<head>
<title>No Choice Specified</title>
</head>

<body bgcolor=lightblue text=green>


<table cellspacing=10>
<tr>

<td><%= $header_image %></td>

<td><h2>No Choice Specified</h2>
<%= $context_bar %>
</td>

</tr>
</table>
<hr>

Sorry, but for your vote to count, you'll need to make a choice.
Please <a href="one-poll.tcl?poll_id=<%= $poll_id %>">return to the poll</a> and
make a choice.

<p>

<ad-footer></ad-footer>

</body>
</html>
