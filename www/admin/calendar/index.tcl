# $Id: index.tcl,v 3.0 2000/02/06 03:09:00 ron Exp $
ReturnHeaders

ns_write "

[ad_admin_header "Calendar Administration"]
<h2>Calendar Administration</h2>
[ad_admin_context_bar "Calendar"]

<hr>

<ul>
"

set db [ns_db gethandle]

set selection [ns_db select $db "select calendar.*, expired_p(expiration_date) as expired_p
from calendar
order by expired_p, creation_date desc"]

set counter 0 
set expired_p_headline_written_p 0
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    incr counter 
    if { $expired_p == "t" && !$expired_p_headline_written_p } {
	ns_write "<h4>Expired Calendar Items</h4>\n"
	set expired_p_headline_written_p 1
    }
    ns_write "<li>[util_AnsiDatetoPrettyDate $start_date] - [util_AnsiDatetoPrettyDate $end_date]: <a href=\"item.tcl?calendar_id=$calendar_id\">$title</a>"
    if { $approved_p == "f" } {
	ns_write "&nbsp; <font color=red>not approved</font>"
    }
    ns_write "\n"
}

ns_write "

<P>

<li><a href=\"categories.tcl\">categories</a>

</ul>

[ad_admin_footer]
"


