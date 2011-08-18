<% # Supplied variables: poll_name, poll_description, choices, form_html, context_bar %>

<%= [ad_header $page_title] %>

<h2><%= $poll_name %></h2>
<%= $context_bar %>

<hr>

<blockquote>

<%= $poll_description %>

<form method=post action=vote.tcl>

<%= $form_html %>

<%= [poll_display $choices] %>

<p>

<input type=submit value=vote>

</form>

</blockquote>

<p>

<%
# kludge around an aolserver 3.0b6 "fancy adp" parsing problem

set href "href=\"poll-results.tcl?poll_id=$poll_id\""
%>

You can <a <%= $href %>>check the results</a> of this poll.

<%= [ad_footer] %>

</body>
</html>
