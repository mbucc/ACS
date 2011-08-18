<% # Supplied variables: poll_name, poll_description, values, header_image, context_bar, poll_id, total_count %>

<%= [ad_header "Results for $poll_name"] %>

<h2>Results for <%= $poll_name %></h2>
<%= $context_bar %>

<hr>

Total of <%= $total_count %> votes

<blockquote>
<%= [poll_results $values] %>
</blockquote>

<%= [ad_footer] %>

</body>
</html>
