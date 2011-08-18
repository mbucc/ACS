<%= [ad_header "Grant Permission"] %>

<h2>Grant Permission</h2>

on <a href=<%= "\"$return_url\"" %>><%= $object_name %></a>

<hr>

Identify user by

<form method=get action="/user-search">

<%= [export_entire_form] %>
<%= [export_form_vars passthrough] %>

<input type=hidden name=target value="/gp/permission-grant-to-user-2">
<table border=0>
<tr><td>Email address:<td><input type=text name=email size=40></tr>
<tr><td colspan=2>or by</tr>
<tr><td>Last name:<td><input type=text name=last_name size=40></tr>
</table>

<p>

<center>
<input type=submit value="Search">
</center>
</form>

<%= [ad_footer] %>
