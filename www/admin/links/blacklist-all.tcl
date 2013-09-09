# /admin/links/blacklist-all.tcl

ad_page_contract {
    The blacklist (all URLs)

    @author Original Author Unknown
    @creation-date Original Date Unknown
    @cvs-id blacklist-all.tcl,v 3.1.6.6 2000/09/22 01:35:29 kevin Exp
} {
}


set page_content "[ad_admin_header "The Blacklist"]

<h2>The Blacklist</h2>

[ad_admin_context_bar [list "index" "Links"] "Spam Blacklist"]

<hr>
<ul>

"

# we go through all the patterns, joining with static_pages (where possible;
# site-wide kill patterns have NULL for page_id) and users table (to see
# which administrator added the pattern)

set pattern_qry "select lkp.pattern_id, lkp.page_id, lkp.date_added, lkp.glob_pattern, sp.url_stub, users.user_id, users.first_names, users.last_name
from link_kill_patterns lkp, static_pages sp, users
where lkp.page_id = sp.page_id(+)
and lkp.user_id = users.user_id
order by sp.url_stub"

set items ""
db_foreach select_blacklist $pattern_qry {
    if ![empty_string_p $url_stub] {
	set scope_description "for <a href=\"$url_stub\">$url_stub</a>"
    } else {
	set scope_description "for this entire site"
    }
    append items "<li>$scope_description: $glob_pattern \[<a href=\"blacklist-remove?[export_url_vars pattern_id]\">REMOVE</a>\]"

} if_no_rows {
    append items "No kill patterns in the database.\n"
}

db_release_unused_handles

append page_content "
$items

</ul>

[ad_admin_footer]
"

doc_return  200 text/html $page_content