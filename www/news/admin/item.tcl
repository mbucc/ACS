# /www/news/admin/item.tcl
#

ad_page_contract {
    news item page

    @author jkoontz@arsdigita.com
    @creation-date March 8, 2000
    @cvs-id item.tcl,v 3.4.2.9 2000/09/22 01:38:58 kevin Exp

    Note: if page is accessed through /groups pages then group_id and 
    group_vars_set are already set up in the environment by the 
    ug_serve_section. group_vars_set contains group related variables
    (group_id, group_name, group_short_name, group_admin_email, 
    group_public_url, group_admin_url, group_public_root_url,
    group_admin_root_url, group_type_url_p, group_context_bar_list and
    group_navbar_list)
} {
    news_item_id:integer,notnull
    scope:optional
    group_id:integer,optional
    public:optional
    contact_info_only:optional
    order_by:optional
}


ad_scope_error_check

news_admin_authorize $news_item_id

set return_url "[ns_conn url]?news_item_id=$news_item_id"

db_0or1row news_item_get "
select n.title, n.body, html_p, n.approval_state, n.release_date, 
       n.expiration_date, n.creation_user, n.creation_date,
       first_names, last_name
from news_items n, users u
where news_item_id = :news_item_id
and u.user_id = n.creation_user"
db_release_unused_handles


if { [empty_string_p $title] && [empty_string_p $body] } {
    ad_scope_return_error "Can't find news item" "Can't find news item $news_item_id"
    return
}

set page_content "
[ad_scope_admin_header "$title"]
[ad_scope_admin_page_title "$title"]
[ad_scope_admin_context_bar [list "" "News"] "One Item"]

<hr>

<ul>
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
<li>Submitted by: [ad_decode $scope public "<a href=\"/admin/users/one?user_id=$creation_user\">$first_names $last_name</a>" group "<a href=\"/shared/community-member?user_id=$creation_user\">$first_names $last_name</a>" unknown]
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

[ad_scope_admin_footer]
"

# [ad_general_comments_list $news_item_id news_items $title news]



doc_return  200 text/html $page_content
