# $Id: index.tcl,v 3.0 2000/02/06 03:29:29 ron Exp $
ReturnHeaders 

ns_write "[ad_admin_header "User Group Administration"]

<h2>User Group Administration</h2>

[ad_admin_context_bar "User Groups"]

<hr>

Currently, the system is able to handle the following types of groups:

<ul>

"

set db [ns_db gethandle]
set selection [ns_db select $db "select ugt.group_type, ugt.pretty_name, count(ug.group_id) as n_groups
from user_group_types ugt, user_groups ug
where ugt.group_type = ug.group_type(+)
group by ugt.group_type, ugt.pretty_name
order by upper(ugt.pretty_name)"]

set count 0 
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    incr count
    ns_write "<li><a href=\"group-type.tcl?group_type=[ns_urlencode $group_type]\">$pretty_name</a> (number of groups defined: $n_groups)\n"
}

if { $count == 0 } {
    ns_write "no group types currently defined"
}

ns_write "<p>

<li><a href=\"group-type-new.tcl\">Define a new group type</a>

</ul>

[ad_admin_footer]
"
