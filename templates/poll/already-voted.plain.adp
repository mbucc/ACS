<% # Supplied variables: poll_name, poll_description, header_image, context_bar, poll_id %>


<%= [ad_header "Sorry!  Already voted for $poll_name"] %>

<h2>Sorry! You already voted for <%= $poll_name %></h2>
<%= $context_bar %>

<hr>

<blockquote>
Sorry! You've already voted for <%= $poll_name %>.

<p>

<%
# kludge around an aolserver 3.0b6 "fancy adp" parsing problem

set href "href=\"poll-results.tcl?poll_id=$poll_id\""
%>

You can <a <%= $href %>>check the results</a> of this poll.

</blockquote>


<%= [ad_footer] %>

</body>
</html>
