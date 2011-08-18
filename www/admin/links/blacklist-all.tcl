# $Id: blacklist-all.tcl,v 3.0 2000/02/06 03:24:25 ron Exp $
set db [ns_db gethandle]

ReturnHeaders

ns_write "[ad_admin_header "The Blacklist"]

<h2>The Blacklist</h2>

[ad_admin_context_bar [list "index.tcl" "Links"] "Spam Blacklist"]

<hr>
<ul>

"

# we go through all the patterns, joining with static_pages (where possible;
# site-wide kill patterns have NULL for page_id) and users table (to see
# which administrator added the pattern)

set selection [ns_db select $db "select lkp.rowid, lkp.page_id, lkp.date_added, lkp.glob_pattern, sp.url_stub, users.user_id, users.first_names, users.last_name
from link_kill_patterns lkp, static_pages sp, users
where lkp.page_id = sp.page_id(+)
and lkp.user_id = users.user_id
order by sp.url_stub"]

set items ""
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    if ![empty_string_p $url_stub] {
	set scope_description "for <a href=\"$url_stub\">$url_stub</a>"
    } else {
	set scope_description "for this entire site"
    }
    append items "<li>$scope_description: $glob_pattern \[<a href=\"blacklist-remove.tcl?rowid=[ns_urlencode $rowid]\">REMOVE</a>\]"

}

if ![empty_string_p $items] {
    ns_write $items
} else {
    ns_write "No kill patterns in the database.\n"
}

ns_write "</ul>

<hr>

<address>philg@mit.edu</address>
</body>
</html>
"
