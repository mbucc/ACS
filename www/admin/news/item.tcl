# /www/admin/news/item.tcl
#

ad_page_contract {
    shows one news item

    @author jkoontz@arsdigita.com
    @creation-date March 8, 2000
    @cvs-id item.tcl,v 3.3.2.6 2000/09/22 01:35:44 kevin Exp
} {
    news_item_id:integer,notnull
    contact_info_only:optional
    order_by:optional
}


set return_url "[ns_conn url]?news_item_id=$news_item_id"


db_0or1row news_item_get "
select n.title, n.body, n.html_p, n.approval_state, n.release_date, n.expiration_date, 
       n.creation_user, n.creation_date, u.first_names, u.last_name, ng.scope, ug.group_name
from news_items n, users u, newsgroups ng, user_groups ug
where news_item_id = :news_item_id
and n.newsgroup_id = ng.newsgroup_id
and ng.group_id = ug.group_id(+)
and u.user_id = n.creation_user"

if { [empty_string_p $title] && [empty_string_p $body] } {
    ad_scope_return_error "Can't find news item" "Can't find news item $news_item_id"
    return
}

db_release_unused_handles


set page_content "
[ad_admin_header "$title"]
<h2>$title</h2>
[ad_admin_context_bar [list "" "News"] "One Item"]

<hr>

<ul>
<li>Scope: $scope $group_name news
<li>Status:  
"

if { [string match $approval_state "approved"] } {
    append page_content "Approved (<a href=\"toggle-approved-p?[export_url_vars news_item_id]\">Revoke</a>)"
} else {
    append page_content "<font color=red>Awaiting approval</font> (<a href=\"toggle-approved-p?[export_url_vars news_item_id]\">Approve</a>)"
}

append page_content "
<li>Release Date: [util_AnsiDatetoPrettyDate $release_date]
<li>Expires: [util_AnsiDatetoPrettyDate $expiration_date]
<li>Submitted by: <a href=\"/admin/users/one?user_id=$creation_user\">$first_names $last_name</a>
</ul>

<h4>Body</h4>

<blockquote>
[util_maybe_convert_to_html $body $html_p]
<br>
<br>
<form action=post-edit method=get>

<input type=hidden name=news_item_id value=\"$news_item_id\">
<input type=submit name=submit value=\"Edit\">
</form>

</blockquote>

[news_item_comments $news_item_id]

[ad_admin_footer]"



doc_return  200 text/html $page_content
