# www/admin/registry/search-one-user.tcl

ad_page_contract {
    @cvs-id search-one-user.tcl,v 3.1.6.3 2000/09/22 01:36:01 kevin Exp
} {
    user_id:integer,notnull
}

proc philg_capitalize { in_string } {
    append out_string [string toupper [string range $in_string 0 0]] [string tolower [string range $in_string 1 [string length $in_string]]]
}


db_1row user_name_get "select first_names, last_name from users where user_id = :user_id"

set sql "select stolen_id,sr.* 
from stolen_registry sr
where user_id = :user_id
order by manufacturer, model"


set html "[ad_admin_header "Entries for $first_names $last_name"]

<h2>Entries for $first_names $last_name</h2>

[ad_admin_context_bar [list "index.tcl" "Registry"] "One User"]

<hr>

<ul>\n"

db_foreach registry_list $sql {
    set pretty_manufacturer [philg_capitalize $manufacturer]    
    # can't use the obvious $serial_number == "" because Tcl
    # is so stupid about numbers
    if { ![string match "" $serial_number] } {
	append html "<li>$pretty_manufacturer $model, serial number <a href=\"one-case?stolen_id=$stolen_id\">$serial_number</a>"
    } else {
	append html "<li>$pretty_manufacturer $model, <a href=\"one-case?stolen_id=$stolen_id\">no serial number provided</a>"
    }

}

append html "
</ul>\n
[ad_admin_footer]"


db_release_unused_handles
doc_return 200 text/html $html
