# $Id: all-adv-groups.tcl,v 3.0 2000/02/06 02:46:09 ron Exp $

set db [ns_db gethandle]

ReturnHeaders

ns_write "[ad_admin_header "Manage Ad Groups"]
<h2>Manage Ad Groups</h2>
at <A href=\"index.tcl\">AdServer Administration</a>
<hr><p>

<ul>
<li> <a href=\"add-adv-group.tcl\">Add</a> a new ad group.
<p>
"

set selection [ns_db select $db "select group_key, pretty_name from adv_groups"]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    
    ns_write "<li> <a href=\"one-adv-group.tcl?group_key=$group_key\">$pretty_name</a>\n"
}

ns_write "</ul>
<p>
[ad_admin_footer]
"