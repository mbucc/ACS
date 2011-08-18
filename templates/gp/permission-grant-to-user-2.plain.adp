<%= [ad_header "Grant Permission to $full_name"] %>

<h2>Grant Permission</h2>

on <a href=<%= "\"$return_url\"" %>><%= $object_name %></a>
to <%= $full_name %>

<hr>

<form action=permission-grant method=post>

<%= [export_form_vars on_what_id on_which_table scope user_id_from_search return_url] %>

<blockquote>

Grant

<blockquote>
<input type=checkbox name=permission_types value=read> read<br>
<input type=checkbox name=permission_types value=comment> comment<br>
<input type=checkbox name=permission_types value=write> write<br>
<input type=checkbox name=permission_types value=administer> administer
</blockquote>

permission on <a href=<%= "\"$return_url\"" %>><%= $object_name %></a>
to <%= $full_name %>

</blockquote>

<center>
<input type=submit value="Submit">
</center>

</form>

<%= [ad_footer] %>
