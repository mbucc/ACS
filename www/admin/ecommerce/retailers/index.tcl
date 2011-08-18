# $Id: index.tcl,v 3.0 2000/02/06 03:21:21 ron Exp $
ReturnHeaders

ns_write "[ad_admin_header "Retailer Administration"]

<h2>Retailer Administration</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] "Retailers"]

<hr>
<h3>Current Retailers</h3>
<ul>
"

set db [ns_db gethandle]
set selection [ns_db select $db "select retailer_id, retailer_name, decode(reach,'web',url,city || ', ' || usps_abbrev) as location from ec_retailers order by retailer_name"]

set retailer_counter 0
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    ns_write "<li><a href=\"one.tcl?retailer_id=$retailer_id\">$retailer_name</a> ($location)\n"
    incr retailer_counter
}

if { $retailer_counter == 0 } {
    ns_write "There are currently no retailers.\n"
}

ns_write "
</ul>
<p>
<h3>Actions</h3>
<ul>
<li><a href=\"add.tcl\">Add New Retailer</a>
</ul>
[ad_admin_footer]
"
