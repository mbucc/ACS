# $Id: search-pls-default-main.tcl,v 3.1 2000/02/23 01:49:39 bdolicki Exp $
set_form_variables
set_form_variables_string_trim_DoubleAposQQ

# query_string, topic

ns_return 200 text/html "<html>
<head>
<title>Search Results Default Main</title>
</head>

<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "black"]>
<h2>Search Results</h2>

from looking through 
<a href=\"main-frame.tcl?[export_url_vars topic topic_id]\" target=\"_top\">
the \"$topic\" BBoard
</a>
for \"$query_string\"

<hr>

The full text index covers the subject line, body, email address, and
name fields of each posting.

<p>


If the results above aren't what you had in mind, then you can refine
your search...

<p>

<form method=GET action=search-pls.tcl target=\"_top\">
<input type=hidden name=topic value=\"$topic\">
<input type=hidden name=topic_id value=\"$topic_id\">
Full Text Search:  <input type=text name=query_string size=40 value=\"$query_string\">
</form>

[bboard_footer]"
