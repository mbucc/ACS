# www/registry/index.tcl

ad_page_contract {
    @cvs-id index.tcl,v 3.1.6.4 2000/09/22 01:39:16 kevin Exp
} {
}

proc philg_capitalize { in_string } {
    append out_string [string toupper [string range $in_string 0 0]] [string tolower [string range $in_string 1 [string length $in_string]]]
}

set sql "select initcap(upper(manufacturer)) as manufacturer,count(*) as count
         from stolen_registry
         group by upper(manufacturer)
         order by upper(manufacturer)"

set html "[ad_header "Stolen Equipment Registry Home"]

<table>
<tr>
<td>
<a href=\"http://photo.net/photo/pcd0305/pool-chairs-empty-29.tcl\"><img src=\"http://photo.net/photo/pcd0305/pool-chairs-empty-29.1.jpg\"></a>

<td>
<h2>Welcome to the Stolen Equipment Registry</h2>

[ad_context_bar_ws_or_index "Registry"]

</tr>
</table>

<hr>
[help_upper_right_menu]

<ul>

<li><a href=\"add\">Add</a>

<p>
"

set items ""
db_foreach manufacturer_list $sql {
    set pretty_manufacturer $manufacturer
    if { $manufacturer == "" } {
	set pretty_manufacturer "(none specified)"
    }

    append items "<li><a href=\"search-one-manufacturer?manufacturer=[ns_urlencode $manufacturer]\">$pretty_manufacturer</a> ($count)\n"

}

append html "
$items
</ul>

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
