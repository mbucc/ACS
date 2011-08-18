# $Id: by-date.tcl,v 3.0 2000/02/06 03:27:56 ron Exp $
proc philg_capitalize { in_string } {
    append out_string [string toupper [string range $in_string 0 0]] [string tolower [string range $in_string 1 [string length $in_string]]]
}

set db [ns_db gethandle]

set selection [ns_db select $db "select stolen_id, posted, manufacturer, model
from stolen_registry
order by posted desc"]

ReturnHeaders

ns_write "[ad_admin_header "All Entries By Date"]

<h2>All Entries By Date</h2>

[ad_admin_context_bar [list "index.tcl" "Registry"] "Entries"]

<hr>
<ul>
"

while {[ns_db getrow $db $selection]} {
    set_variables_after_query

    ns_write "<li>$posted <a href=\"one-case.tcl?stolen_id=$stolen_id\">$manufacturer $model</a>\n"
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

[ad_admin_footer]
"
