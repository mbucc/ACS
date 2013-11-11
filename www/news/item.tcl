# /www/news/item.tcl
#

ad_page_contract {
    news item page
    
    @author jkoontz@arsdigita.com
    @creation-date March 8, 2000
    @cvs-id item.tcl,v 3.5.2.9 2000/09/22 01:38:57 kevin Exp
    
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
    user_id:integer,optional
    group_id:integer,optional
    on_which_group:optional
    on_what_id:integer,optional
    contact_info_only:optional
    order_by:optional
}


ad_scope_error_check

# If we got a parameter named news_id, and news_item_id has not been defined,
# we copy news_id's value.
if { [exists_and_not_null news_id] && ![exists_and_not_null news_item_id] } {
    set news_item_id $news_id
}

set user_id [ad_scope_authorize $scope all all all]

db_0or1row news_item_get "
select title, body, html_p, 
       n.approval_state, release_date, expiration_date,
       creation_user, creation_date, first_names, last_name
from news_items n, users u
where news_item_id = :news_item_id
and u.user_id = n.creation_user"

if { [empty_string_p $title] && [empty_string_p $body] } {
    ad_scope_return_error "Can't find news item" "Can't find news item $news_item_id"
    return
}
db_release_unused_handles


append page_content "<header>[ad_scope_header $title]"

if { $scope=="public" } {
    append page_content "
    [ad_decorate_top "<h2>$title</h2> [ad_context_bar_ws_or_index [list "index.tcl?[export_url_scope_vars]" "News"] "One Item"]" [ad_parameter ItemPageDecoration news]]"
} else {
    append page_content "
    [ad_scope_page_title $title]
    [ad_scope_context_bar_ws_or_index [list "index.tcl?[export_url_scope_vars]" "News"] "One Item"]
    "
}

append page_content "
[ad_scope_navbar]
</header>

<blockquote>
[util_maybe_convert_to_html $body $html_p]
</blockquote>

<p>
Contributed by <a href=\"/shared/community-member?[export_url_vars]&user_id=$creation_user\">$first_names $last_name</a>.
</p>

[ad_general_comments_list $news_item_id news_items $title news]

[ad_scope_footer]
"



doc_return  200 text/html $page_content
