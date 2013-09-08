# www/registry/search-one-manufacturer.tcl

ad_page_contract {
    @cvs-id search-one-manufacturer.tcl,v 3.2.2.4 2000/09/22 01:39:16 kevin Exp
} {
    manufacturer    
}

proc philg_capitalize { in_string } {
    append out_string [string toupper [string range $in_string 0 0]] [string tolower [string range $in_string 1 [string length $in_string]]]
}

if { $manufacturer == "" } {
    set where_clause "manufacturer is null"
} else {
    set where_clause "upper(manufacturer) = upper('[DoubleApos $manufacturer]')"
}

set sql "select stolen_id,sr.* 
         from stolen_registry sr
         where $where_clause
         order by model"

set pretty_manufacturer [philg_capitalize $manufacturer]

set html "[ad_header "$pretty_manufacturer Entries"]

<h2>$pretty_manufacturer Entries</h2>

[ad_context_bar_ws_or_index [list "index.tcl" "Registry"] "One Manufacturer"]

<hr>

<ul>\n"

db_foreach stolen_registry_list $sql {
    # can't use the obvious $serial_number == "" because Tcl
    # is so stupid about numbers
    if { ![string match "" $serial_number] } {
	append html "<li>$model, serial number <a href=\"one-case?stolen_id=$stolen_id\">$serial_number</a>"
    } else {
	append html "<li>$model, <a href=\"one-case?stolen_id=$stolen_id\">no serial number provided</a>"
    }

}

append html "</ul>

[ad_footer]
"


doc_return  200 text/html $html
