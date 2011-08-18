# $Id: all-advs.tcl,v 3.0 2000/02/06 02:46:09 ron Exp $

set db [ns_db gethandle]

ReturnHeaders

ns_write "[ad_admin_header "Manage Ads"]
<h2>Manage Ads</h2>
at <A href=\"index.tcl\">AdServer Administration</a>
<hr><p>

<ul>
<li> <a href=\"add-adv.tcl\">Add</a> a new ad.
<p>
"

set selection [ns_db select $db "select adv_key
from advs
order by upper(adv_key)"]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    
    ns_write "<li> <a href=\"one-adv.tcl?adv_key=$adv_key\">$adv_key</a>\n"
}

ns_write "</ul>
<p>
[ad_admin_footer]
"
