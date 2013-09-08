# www/admin/registry/by-date.tcl

ad_page_contract {
    @cvs-id by-date.tcl,v 3.1.6.3 2000/09/22 01:36:00 kevin Exp
} {    
}
 
proc philg_capitalize { in_string } {
    append out_string [string toupper [string range $in_string 0 0]] [string tolower [string range $in_string 1 [string length $in_string]]]
}

set sql "select stolen_id, posted, manufacturer, model
from stolen_registry
order by posted desc"


set html "[ad_admin_header "All Entries By Date"]

<h2>All Entries By Date</h2>

[ad_admin_context_bar [list "index.tcl" "Registry"] "Entries"]

<hr>
<ul>
"

db_foreach registry_list $sql {
    append html "<li>$posted <a href=\"one-case?stolen_id=$stolen_id\">$manufacturer $model</a>\n"
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

