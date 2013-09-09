# /admin/links/by-user.tcl

ad_page_contract {
    Show links by the user who created them.

    @author Original Author Unknown
    @creation-date Original Date Unknown
    @cvs-id by-user.tcl,v 3.1.6.5 2000/09/22 01:35:29 kevin Exp
} {
}

set page_content "[ad_admin_header "Related links per user"]

<h2>Related links per user</h2>

[ad_admin_context_bar [list "index" "Links"] "By User"]

<hr>
 
<ul>
"


set sql_qry "select links.user_id, first_names, last_name, count(links.page_id) as n_links
from links, users
where links.user_id = users.user_id
group by links.user_id, first_names, last_name
order by n_links desc"

set items ""

db_foreach select_user_links $sql_qry {
    append items "<li><a href=\"/admin/users/one?user_id=$user_id\">$first_names $last_name</a> ($n_links)\n"
}

db_release_unused_handles
 
append page_content "
$items

</ul>

[ad_admin_footer]
"

doc_return  200 text/html $page_content
