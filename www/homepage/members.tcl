# File:     /homepage/members.tcl

ad_page_contract {
    Page to show members of a particular neighborhood

    @param neighborhood_node System variable to help us get back to the start
    @param nid The neighborhood ID to identify which one we're looking at

    @author Usman Y. Mobin (mobin@mit.edu)
    @creation-date Thu Jan 27 05:45:19 EST 2000
    @cvs-id members.tcl,v 3.1.2.9 2000/09/22 01:38:17 kevin Exp
} {
    neighborhood_node:notnull,naturalnum
    nid:notnull,naturalnum
}

set nh_name [db_string select_neighborhood_name {
select hp_relative_neighborhood_name(:nid) 
from dual}]

set title "Members of $nh_name"

# packet of page content
set page_content "
[ad_header $title]
<h2>$title</h2>
[ad_context_bar_ws_or_index [list "neighborhoods?neighborhood_node=$neighborhood_node" "Neighborhoods"] $title] 
<hr>
<blockquote>

    <table bgcolor=DDEEFF border=0 cellspacing=0 cellpadding=8 width=90%>
    <tr><td>
    <b>These are the members of $nh_name</b>
    <ul>

<table border=0>
"

set counter 0

set member_qry "
select uh.user_id as user_id,
u.screen_name as screen_name,
u.first_names as first_names,
u.last_name as last_name
from users_homepages uh, users u
where uh.user_id=u.user_id
and uh.neighborhood_id=:nid
order by last_name desc, first_names desc"

db_foreach select_neighborhood_members $member_qry {
    incr counter
    append page_content "
    <tr>
    <td><a href=\"/users/$screen_name\">$last_name, $first_names</a>
    </td>
    </tr>
    "
} if_no_rows {
    append page_content "
    <tr>
    <td>This neighborhood has no members
    </td>
    </tr>
    "
}

# Finished with the database handle
db_release_unused_handles

set page_content "
$page_content
</table>
</ul>
$counter member(s)
</table>
</blockquote>
[ad_footer]
"

# Return the page
doc_return  200 text/html $page_content

