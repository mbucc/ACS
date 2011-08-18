# $Id: by-user.tcl,v 3.0 2000/02/06 03:24:32 ron Exp $
ReturnHeaders

ns_write "[ad_admin_header "Related links per user"]

<h2>Related links per user</h2>

[ad_admin_context_bar [list "index.tcl" "Links"] "By User"]

<hr>
 
<ul>
"

set db [ns_db gethandle]

set selection [ns_db select $db "select links.user_id, first_names, last_name, count(links.page_id) as n_links
from links, users
where links.user_id = users.user_id
group by links.user_id, first_names, last_name
order by n_links desc"]

set items ""

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    append items "<li><a href=\"/admin/users/one.tcl?user_id=$user_id\">$first_names $last_name</a> ($n_links)\n"
}
 
ns_write $items

ns_write "
</ul>

[ad_admin_footer]
"
