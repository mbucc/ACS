# iso-codes.tcl

ad_page_contract {
    @author ?
    @creation-date ?
    @cvs-id iso-codes.tcl,v 3.2.2.3 2000/09/22 01:39:18 kevin Exp
} {
}

append doc_body  "<html>
<head>
<title>Complete List of ISO Codes</title>
</head>
<body bgcolor=#ffffff text=#000000>
<h2>Complete List of ISO Codes</h2>

Please locate your country's code among those listed below then use
the \"back\" button on your browser to return to the previous form.

<hr>
<table>
<tr><th align=left>Country Name<th>ISO Code</tr>
"

set sql "select * from country_codes order by country_name"

db_foreach country_list $sql {   
    append doc_body "<tr><td>$country_name<td align=center>$iso</tr>\n"
}

append doc_body "
</table>
<hr>
</body>
</html>"

db_release_unused_handles
doc_return 200 text/html $doc_body
