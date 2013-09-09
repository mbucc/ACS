<html>
  <head>
    <title><%= $title %></title>
  </head>
<body bgcolor=white>
  <h2><%= $title %></h2>
  <%= [eval ad_context_bar_ws $navbar] %>
  <hr>
  <%= $body %>
  <hr>
  <a href=mailto:<%= $author %>><address><%= $author %></address></a>
</body>
</html>

