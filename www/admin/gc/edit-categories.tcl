# $Id: edit-categories.tcl,v 3.0.4.1 2000/03/15 05:09:06 curtisg Exp $
set db [ns_db gethandle]

set selection [ns_db select $db "select * from ad_domains"]
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    append bullet_list "<li><a href=\"domain-top.tcl?domain_id=$domain_id\">$backlink_title</a>\n"
}

ns_return 200 text/html "<html>
<head>
<title>Pick a Domain</title>
</head>
<body bgcolor=#ffffff text=#000000>
<h2>Pick a Domain</h2>

<hr>

<ul>

$bullet_list

</ul>


<hr>
<a href=\"http://www-swiss.ai.mit.edu/philg/\"><address>philg@mit.edu</address></a>

</body>
</html>"
