#
# /www/admin/news/item.tcl
#
# shows one news item
#
# Author: jkoontz@arsdigita.com March 8, 2000
#
# $Id: item.tcl,v 3.1 2000/03/10 23:45:54 jkoontz Exp $

set_the_usual_form_variables 0
# news_item_id
# maybe contact_info_only, maybe order_by

set return_url "[ns_conn url]?news_item_id=$news_item_id"

set db [ns_db gethandle]
set selection [ns_db 0or1row $db "
select n.title, n.body, n.html_p, n.approval_state, n.release_date, n.expiration_date, 
  n.creation_user, n.creation_date, u.first_names, u.last_name, ng.scope, ug.group_name
from news_items n, users u, newsgroups ng, user_groups ug
where news_item_id = $news_item_id
and n.newsgroup_id = ng.newsgroup_id
and ng.group_id = ug.group_id(+)
and u.user_id = n.creation_user"]

if { $selection == "" } {
    ad_scope_return_error "Can't find news item" "Can't find news item $news_item_id" $db
    return
}

set_variables_after_query

append page_content "
[ad_admin_header "$title"]
<h2>$title</h2>
[ad_admin_context_bar [list "index.tcl" "News"] "One Item"]

<hr>

<ul>
<li>Scope: $scope $group_name news
<li>Status:  
"

if { [string match $approval_state "approved"] } {
    append page_content "Approved (<a href=\"toggle-approved-p.tcl?[export_url_vars news_item_id]\">Revoke</a>)"
} else {
    append page_content "<font color=red>Awaiting approval</font> (<a href=\"toggle-approved-p.tcl?[export_url_vars news_item_id]\">Approve</a>)"
}

append page_content "
<li>Release Date: [util_AnsiDatetoPrettyDate $release_date]
<li>Expires: [util_AnsiDatetoPrettyDate $expiration_date]
<li>Submitted by: <a href=\"/admin/users/one.tcl?user_id=$creation_user\">$first_names $last_name</a>
</ul>

<h4>Body</h4>

<blockquote>
[util_maybe_convert_to_html $body $html_p]
<br>
<br>
<form action=post-edit.tcl method=get>

<input type=hidden name=news_item_id value=\"$news_item_id\">
<input type=submit name=submit value=\"Edit\">
</form>

</blockquote>

[ad_general_comments_list $db $news_item_id news_items $title news]

[ad_admin_footer]"

ns_db releasehandle $db

ns_return 200 text/html $page_content