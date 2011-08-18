<% # Supplied variables: header_image, context_bar, poll_id %>

<%= [ad_header "Thanks for your vote"] %>

<h2>Thank you for your vote</h2>
<%= $context_bar %>

<hr>

<blockquote>

<%
# kludge around an aolserver 3.0b6 "fancy adp" parsing problem

set href "href=\"poll-results.tcl?poll_id=$poll_id\""
%>

You can <a <%= $href %>>check the results</a> of this poll.

</blockquote>

<p>

<%= [ad_footer] %>

</body>
</html>
