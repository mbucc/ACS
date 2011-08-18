# $Id: search-one-manufacturer.tcl,v 3.0 2000/02/06 03:54:15 ron Exp $
proc philg_capitalize { in_string } {
    append out_string [string toupper [string range $in_string 0 0]] [string tolower [string range $in_string 1 [string length $in_string]]]
}

set_the_usual_form_variables
# manufacturer

set db [ns_db gethandle]

if { $manufacturer == "" } {
    set where_clause "manufacturer is null"
} else {
    set where_clause "upper(manufacturer) = upper('$QQmanufacturer')"
}

set selection [ns_db select $db "select stolen_id,sr.* 
from stolen_registry sr
where $where_clause
order by model"]

set pretty_manufacturer [philg_capitalize $manufacturer]

ReturnHeaders

ns_write "[ad_header "$pretty_manufacturer Entries"]

<h2>$pretty_manufacturer Entries</h2>

[ad_context_bar_ws_or_index [list "index.tcl" "Registry"] "One Manufacturer"]


<hr>

<ul>\n"

while {[ns_db getrow $db $selection]} {

    set_variables_after_query
    # can't use the obvious $serial_number == "" because Tcl
    # is so stupid about numbers
    if { ![string match "" $serial_number] } {
	ns_write "<li>$model, serial number <a href=\"one-case.tcl?stolen_id=$stolen_id\">$serial_number</a>"
    } else {
	ns_write "<li>$model, <a href=\"one-case.tcl?stolen_id=$stolen_id\">no serial number provided</a>"
    }

}

ns_write "</ul>

[ad_footer]
"
