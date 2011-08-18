<%= [ad_header "Grant Permission"] %>

<h2>Grant Permission</h2>

on <a href=<%= "\"$return_url\"" %>><%= $object_name %></a>

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
to

<blockquote>
<input type=radio name=scope value=group> all members<br>
<input type=radio name=scope value=group_role> members in the role:
<input type=text name=role size=20 maxlength=20>
</blockquote>

of <%= $user_group_widget %>

</blockquote>

<center>
<input type=submit value="Submit">
</center>

</form>

<%= [ad_footer] %>
