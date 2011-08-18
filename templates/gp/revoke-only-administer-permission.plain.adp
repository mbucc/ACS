<% set object_link "<a href=\"$return_url\">$object_name</a>" %>
<%= [ad_header "Revoke Only Administer Permission"] %>

<h2>Revoke Only Administer Permission</h2>

on <%= $object_link %>

<hr>

<form action=permission-revoke method=post>

<%= [export_form_vars on_what_id on_which_table permission_id return_url] %>

<center>

This is the only <strong>Administer</strong> permission granted on
<%= $object_link %>.

<p>

Are you sure that you want to revoke it?

<p>

<input type=submit value="Yes, revoke it now">
<input type=button value="No, go back" onclick="history.back()">

</center>

</form>

<%= [ad_footer] %>
