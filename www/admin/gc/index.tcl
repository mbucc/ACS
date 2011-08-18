# $Id: index.tcl,v 3.1 2000/03/11 00:45:12 curtisg Exp $
append html "[ad_admin_header "Classified Administration"]

<h2>Classified Administration</h2>

[ad_admin_context_bar "Classifieds"]

<hr>
<ul>

<h4>Active domains</h4>"

set db [gc_db_gethandle]

set selection [ns_db select $db "select * 
from ad_domains
order by active_p desc, upper(domain)"]

set count 0
set inactive_title_shown_p 0

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { $active_p == "f" } {
	if { $inactive_title_shown_p == 0 } {
	    # we have not shown the inactive title yet
	    if { $count == 0 } {
		append html "<li>No active domains"
	    }
	    set inactive_title_shown_p 1
	    append html "<h4>Inactive domains</h4>"
	}
	set anchor "activate"
    } else {
	set anchor "deactivate"
    }

    set_variables_after_query

    append html "<li><a href=\"domain-top.tcl?domain_id=$domain_id\">$domain</a>\n  (<a href=\"toggle-active-p.tcl?[export_url_vars domain_id]\">$anchor</a>)\n"
    incr count
}

append html "

<p>

<li><a href=\"domain-add.tcl\">create a new domain</a>

</ul>

[ad_admin_footer]"

ns_db releasehandle $db
ns_return 200 text/html $html
