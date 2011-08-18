<html>
<head>
<title>Administer Permissions</title>
<style type=text/css>
BODY {
  background-color: #FFFFFF;
  color: #000000
}

TH {
  background-color: #C0C0C0;
  color: #000000
}

TR.odd {
  background-color: #FFFFFF;
  color: #000000
}

TR.even {
  background-color: #D0D0D0;
  color: #000000
}
</style>
</head>

<body>

<h2>Administer Permissions</h2>

for <a href=<%= "\"$return_url\"" %>><%= $object_name %></a>

<hr>

<blockquote>

<%= $permission_grid %>

<ul>
<li><%= $grant_permission_to_user_link %>
<li><%= $grant_permission_to_group_link %>
<li>Go <a href=<%= "\"$return_url\"" %>>back</a> to where you were
</ul>

</blockquote>

<%= [ad_footer] %>

