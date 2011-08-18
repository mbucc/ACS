<% # Supplied variables: poll_name, poll_description, header_image, context_bar, poll_id %>

<%= [ad_header "Poll Not Active"] %>


<h2>Poll "<%= $poll_name %>" Not Active</h2>
<%= $context_bar %>
<hr>

<blockquote>

Sorry, but the poll "<%= $poll_name %>" is not active at this time.

</blockquote>

<p>

<%= [ad_footer] %>
