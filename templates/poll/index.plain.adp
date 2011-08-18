<% # Supplied variables: page_title, header_image, context_bar, polls  %>

<%= [ad_header $page_title] %>

<h2>Polls</h2>
<%= $context_bar %>

<hr>

<ul>
<%= [poll_front_page $polls] %>

</ul>

<p>

<%= [ad_footer] %>

</body>
</html>
