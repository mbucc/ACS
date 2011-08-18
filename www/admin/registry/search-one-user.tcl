# $Id: search-one-user.tcl,v 3.0 2000/02/06 03:28:04 ron Exp $
proc philg_capitalize { in_string } {
    append out_string [string toupper [string range $in_string 0 0]] [string tolower [string range $in_string 1 [string length $in_string]]]
}

set_the_usual_form_variables
# user_id

set db [ns_db gethandle]

set selection [ns_db 1row $db "select first_names, last_name from users where user_id = $user_id"]
set_variables_after_query

set selection [ns_db select $db "select stolen_id,sr.* 
from stolen_registry sr
where user_id = $user_id
order by manufacturer, model"]

ReturnHeaders

ns_write "[ad_admin_header "Entries for $first_names $last_name"]

<h2>Entries for $first_names $last_name</h2>

[ad_admin_context_bar [list "index.tcl" "Registry"] "One User"]

<hr>

<ul>\n"

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    set pretty_manufacturer [philg_capitalize $manufacturer]
    
    # can't use the obvious $serial_number == "" because Tcl
    # is so stupid about numbers
    if { ![string match "" $serial_number] } {
	ns_write "<li>$pretty_manufacturer $model, serial number <a href=\"one-case.tcl?stolen_id=$stolen_id\">$serial_number</a>"
    } else {
	ns_write "<li>$pretty_manufacturer $model, <a href=\"one-case.tcl?stolen_id=$stolen_id\">no serial number provided</a>"
    }

}

ns_write "</ul>\n"

ns_write [ad_admin_footer]
