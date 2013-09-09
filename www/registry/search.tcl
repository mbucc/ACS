# www/registry/search.tcl

ad_page_contract {
    @cvs-id search.tcl,v 3.1.6.4 2000/09/22 01:39:16 kevin Exp
} {
}

proc philg_capitalize { in_string } {
    append out_string [string toupper [string range $in_string 0 0]] [string tolower [string range $in_string 1 [string length $in_string]]]
}

set sql "select initcap(upper(manufacturer)) as manufacturer,count(*) as count
         from stolen_registry
         group by upper(manufacturer)
         order by upper(manufacturer)"

set html "[ad_header "Search Stolen Equipment Registry"]

<h2>Search</h2>

the <a href=index>Stolen Equipment Registry</a>

<hr>

Pick a manufacturer...

<ul>
"

db_foreach manufacturer_list $sql {
    append html "<li><a href=\"search-one-manufacturer?manufacturer=[ns_urlencode $manufacturer]\">$manufacturer</a> ($count)"

}

append html "</ul>\n

or 

<form method=post action=search-pls>
Search by full text query:  <input type=text name=query_string size=40>
</form>
<p>
Note: this searches through names, email addresses, stories, manufacturers, models, and 
serial numbers.

[ad_footer]
"


doc_return  200 text/html $html
