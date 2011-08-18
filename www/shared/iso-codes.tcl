# $Id: iso-codes.tcl,v 3.1 2000/02/29 04:38:57 jsc Exp $
ReturnHeaders 

ns_write  "<html>
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

set db [ns_db gethandle]

set selection [ns_db select $db "select * from country_codes
order by country_name"]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    ns_write "<tr><td>$country_name<td align=center>$iso</tr>\n"

}



ns_write "

</table>

<hr>


</body>
</html>"
