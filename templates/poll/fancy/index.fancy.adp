<% # Supplied variables: page_title, header_image, context_bar, polls  %>

<html>
<head>
<title><%= $page_title %></title>

</head>

<body bgcolor=lightblue text=red>


<table cellspacing=10>
<tr>

<td><%= $header_image %></td>


<td><h2>Polls</h2>
<%= $context_bar %>
</td>

</tr>
</table>
<hr>

<center>
<table border=1 bgcolor=white>
<%= [poll_front_page -item_start "<tr><td>" -style_start "<font color=green>" -style_end "</font>" -require_registration_start "<td>" -require_registration_text "<font color=blue>Registration Mandatory!!!</font>"  $polls] %>
</table>
</center>

<p>

<center>
<font size=-1>Go to the <a href="/news-templated/graphics-prefs.tcl?prefer_text_only_p=t&return_url=/poll/index.tcl">plain version</a> of this page;<br>
</font>
</center>

<ad-footer></ad-footer>

</body>
</html>
