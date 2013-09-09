# www/admin/registry/index.tcl

ad_page_contract {
    @cvs-id index.tcl,v 3.2.2.3 2000/09/22 01:36:01 kevin Exp
} {
}

proc philg_capitalize { in_string } {
    append out_string [string toupper [string range $in_string 0 0]] [string tolower [string range $in_string 1 [string length $in_string]]]
}


set sql "select initcap(upper(manufacturer)) as manufacturer, count(*) as count
from stolen_registry
group by upper(manufacturer)
order by upper(manufacturer)"


set html "[ad_admin_header "Stolen Equipment Registry Admininistration"]

<h2>Stolen Equipment Registry Administration</h2>

[ad_admin_context_bar "Registry"]

<hr>

 \[ <a href=\"by-date\">View all entries sorted by date</a> &nbsp;|&nbsp;
    <a href=\"by-user\">View all entries by user</a> \]

<ul>
"

db_foreach manufacturer $sql {
    append html "<li><a href=\"search-one-manufacturer?manufacturer=[ns_urlencode $manufacturer]\">$manufacturer ($count)</a>"

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

[ad_admin_footer]
"

db_release_unused_handles
doc_return 200 text/html $html
