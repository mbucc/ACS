ad_page_contract {
    @cvs-id search.tcl,v 3.2.2.3 2000/09/22 01:36:02 kevin Exp
} {    
}


proc philg_capitalize { in_string } {
    append out_string [string toupper [string range $in_string 0 0]] [string tolower [string range $in_string 1 [string length $in_string]]]
}


set sql "select initcap(upper(manufacturer)) as manufacturer,count(*) as count
         from stolen_registry
         group by upper(manufacturer)
         order by upper(manufacturer)"


set html "<html>
<head>

<title>Search Stolen Equipment Registry</title>
</head>
<body bgcolor=#ffffff text=#000000>

<h2>Search</h2>

the <a href=index>Stolen Equipment Registry</a>

<hr>

Pick a manufacturer...

<ul>
"

db_foreach manufacturer_list $sql {
    append html "<li><a href=\"search-one-manufacturer?manufacturer=[ns_urlencode $manufacturer]\">$manufacturer</a> ($count)"
}

append html "</ul>\n"
append html "
or 

<form method=post action=search-pls>
Search by full text query:  <input type=text name=query_string size=40>
</form>
<p>
Note: this searches through names, email addresses, stories, manufacturers, models, and 
serial numbers.

<hr>

<address>photo.net@martigny.ai.mit.edu</a>

</body>
</html>"

db_release_unused_handles
doc_return 200 text/html $html
