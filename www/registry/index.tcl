# $Id: index.tcl,v 3.0 2000/02/06 03:54:12 ron Exp $
proc philg_capitalize { in_string } {
    append out_string [string toupper [string range $in_string 0 0]] [string tolower [string range $in_string 1 [string length $in_string]]]
}

set db [ns_db gethandle]

set selection [ns_db select $db "select initcap(upper(manufacturer)) as manufacturer,count(*) as count
from stolen_registry
group by upper(manufacturer)
order by upper(manufacturer)"]

ReturnHeaders

ns_write "[ad_header "Stolen Equipment Registry Home"]

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

<li><a href=\"add.html\">Add</a>

<p>

"

set items ""
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    set pretty_manufacturer $manufacturer
    if { $manufacturer == "" } {
	set pretty_manufacturer "(none specified)"
    }

    append items "<li><a href=\"search-one-manufacturer.tcl?manufacturer=[ns_urlencode $manufacturer]\">$pretty_manufacturer</a> ($count)\n"

}

ns_write "
$items
</ul>

or 

<form method=post action=search-pls.tcl>
Search by full text query:  <input type=text name=query_string size=40>
</form>
<p>
Note: this searches through names, email addresses, stories, manufacturers, models, and 
serial numbers.

[ad_footer]
"
