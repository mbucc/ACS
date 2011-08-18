# $Id: members.tcl,v 3.0 2000/02/06 03:46:45 ron Exp $
# File:     /homepage/members.tcl
# Date:     Thu Jan 27 05:45:19 EST 2000
# Location: 42Å∞21'N 71Å∞04'W
# Location: 80 PROSPECT ST CAMBRIDGE MA 02139 USA
# Author:   mobin@mit.edu (Usman Y. Mobin)
# Purpose:  Page to show members of a particular neighborhood

	
set_form_variables
# neighborhood_node, nid

set db [ns_db gethandle]

set nh_name [database_to_tcl_string $db "
select hp_relative_neighborhood_name($nid) 
from dual"]

ReturnHeaders

set title "Members of $nh_name"

# packet of html
ns_write "
[ad_header $title]
<h2>$title</h2>
[ad_context_bar_ws_or_index [list "neighborhoods.tcl?neighborhood_node=$neighborhood_node" "Neighborhoods"] $title] 
<hr>
<blockquote>

    <table bgcolor=DDEEFF border=0 cellspacing=0 cellpadding=8 width=90%>
    <tr><td>
    <b>These are the members of $nh_name</b>
    <ul>

"

set selection [ns_db select $db "
select uh.user_id as user_id,
u.screen_name as screen_name,
u.first_names as first_names,
u.last_name as last_name
from users_homepages uh, users u
where uh.user_id=u.user_id
and uh.neighborhood_id=$nid
order by last_name desc, first_names desc"]

append html "
<table border=0>
"

set counter 0

while {[ns_db getrow $db $selection]} {
    incr counter
    set_variables_after_query
    append html "
    <tr>
    <td><a href=\"/users/$screen_name\">$last_name, $first_names</a>
    </td>
    </tr>
    "
}

# And finally, we're done with the database (duh)
ns_db releasehandle $db

if {$counter == 0} {
    append html "
    <tr>
    <td>This neighborhood has no members
    </td>
    </tr>
    "
}

append html "
</table>
</ul>
$counter member(s)
</table>
</blockquote>
"

ns_write "
$html
[ad_footer]
"


