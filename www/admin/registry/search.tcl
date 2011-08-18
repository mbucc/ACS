# $Id: search.tcl,v 3.0 2000/02/06 03:28:07 ron Exp $
proc philg_capitalize { in_string } {
    append out_string [string toupper [string range $in_string 0 0]] [string tolower [string range $in_string 1 [string length $in_string]]]
}

set db [ns_db gethandle]

set selection [ns_db select $db "select initcap(upper(manufacturer)) as manufacturer,count(*) as count
from stolen_registry
group by upper(manufacturer)
order by upper(manufacturer)"]

ReturnHeaders

ns_write "<html>
<head>

<title>Search Stolen Equipment Registry</title>
</head>
<body bgcolor=#ffffff text=#000000>

<h2>Search</h2>

the <a href=index.tcl>Stolen Equipment Registry</a>

<hr>

Pick a manufacturer...

<ul>
"

while {[ns_db getrow $db $selection]} {

    set_variables_after_query

    ns_write "<li><a href=\"search-one-manufacturer.tcl?manufacturer=[ns_urlencode $manufacturer]\">$manufacturer</a> ($count)"

}

ns_write "</ul>\n"

ns_write "
or 

<form method=post action=search-pls.tcl>
Search by full text query:  <input type=text name=query_string size=40>
</form>
<p>
Note: this searches through names, email addresses, stories, manufacturers, models, and 
serial numbers.

<hr>


<address>photo.net@martigny.ai.mit.edu</a>


</body>
</html>"
