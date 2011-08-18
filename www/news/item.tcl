#
# /www/news/item.tcl
#
# news item page
#
# Author: jkoontz@arsdigita.com March 8, 2000
#
# $Id: item.tcl,v 3.1.2.1 2000/04/03 09:15:08 carsten Exp $

# Note: if page is accessed through /groups pages then group_id and 
# group_vars_set are already set up in the environment by the 
# ug_serve_section. group_vars_set contains group related variables
# (group_id, group_name, group_short_name, group_admin_email, 
# group_public_url, group_admin_url, group_public_root_url,
# group_admin_root_url, group_type_url_p, group_context_bar_list and
# group_navbar_list)

set_the_usual_form_variables
# news_item_id
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)
# maybe contact_info_only, maybe order_by

ad_scope_error_check


# If we got a parameter named news_id, and news_item_id has not been defined,
# we copy news_id's value.
if { [exists_and_not_null news_id] && ![exists_and_not_null news_item_id] } {
    set news_item_id $news_id
}


set db [ns_db gethandle]
set selection [ns_db 0or1row $db "
select title, body, html_p, n.approval_state, release_date, expiration_date, creation_user, creation_date, first_names, last_name
from news_items n, users u
where news_item_id = $news_item_id
and u.user_id = n.creation_user"]

if { $selection == "" } {
    ad_scope_return_error "Can't find news item" "Can't find news item $news_item_id" $db
    return
}

set user_id [ad_scope_authorize $db $scope all all all ]

set_variables_after_query

append page_content "
[ad_scope_header $title $db]
"

if { $scope=="public" } {
    append page_content "
    [ad_decorate_top "<h2>$title</h2> [ad_context_bar_ws_or_index [list "index.tcl?[export_url_scope_vars]" "News"] "One Item"]" [ad_parameter ItemPageDecoration news]]"
} else {
    append page_content "
    [ad_scope_page_title $title $db]
    [ad_scope_context_bar_ws_or_index [list "index.tcl?[export_url_scope_vars]" "News"] "One Item"]
    "
}

append page_content "
<hr>
[ad_scope_navbar]

<blockquote>
[util_maybe_convert_to_html $body $html_p]
</blockquote>

Contributed by <a href=\"/shared/community-member.tcl?[export_url_scope_vars]&user_id=$creation_user\">$first_names $last_name</a>.

[ad_general_comments_list $db $news_item_id news_items $title news]

[ad_scope_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $page_content



