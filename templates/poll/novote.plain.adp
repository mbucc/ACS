<% # Supplied variables: header_image, context_bar, poll_id %>

<%= [ad_header "No Choice Specified"] %>

<h2>No Choice Specified</h2>
<%= $context_bar %>

<hr>

<blockquote>

Sorry, but for your vote to count, you'll need to make a choice.

<%
# kludge around an aolserver 3.0b6 "fancy adp" parsing problem

set href "href=\"one-poll.tcl?poll_id=$poll_id\""
%>

Please <a <%= $href %>>return to the poll</a> and
make a choice.

</blockquote>

<%= [ad_footer] %>

</body>
</html>
