#
# /www/news/index.tcl
#
# news main page
#
# Author: jkoontz@arsdigita.com March 8, 2000
#
# $Id: index.tcl,v 3.2 2000/03/10 23:45:33 jkoontz Exp $

# Note: if page is accessed through /groups pages then group_id and 
# group_vars_set are already set up in the environment by the 
# ug_serve_section. group_vars_set contains group related variables
# (group_id, group_name, group_short_name, group_admin_email, 
# group_public_url, group_admin_url, group_public_root_url,
# group_admin_root_url, group_type_url_p, group_context_bar_list and
# group_navbar_list)

set_the_usual_form_variables 0
# possibly archive_p 
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)

ad_scope_error_check

if { [info exists archive_p] && $archive_p } {
    set page_title "News Archives"
} else {
    set page_title "News"
}

set db_conns [ns_db gethandle [philg_server_default_pool] 2]
set db [lindex $db_conns 0]
set db_sub [lindex $db_conns 1]
ad_scope_authorize $db $scope all group_member none

append page_content "
[ad_scope_header $page_title $db]
"

if { $scope=="public" } {
    append page_content "
    [ad_decorate_top "<h2>$page_title</h2>[ad_scope_context_bar_ws_or_index "News"]" \
	    [ad_parameter IndexPageDecoration news]]
    "
} else {
    append page_content "
    [ad_scope_page_title $page_title $db]
    [ad_scope_context_bar_ws_or_index "News"]
    "
}

append page_content "
<hr>
[ad_scope_navbar]
<ul>
"

if { ![info exists user_id] } { 
    set user_id 0
}
if { ![info exists group_id] } {
    set group_id 0
}

# Create a clause for returning the postings for relavent groups
set newsgroup_clause "(newsgroup_id = [join [news_newsgroup_id_list $db $user_id $group_id] " or newsgroup_id = "])"

if { [info exists archive_p] && $archive_p } {
    set query "
    select news_item_id, title, release_date, body, html_p
    from news_items
    where sysdate > expiration_date
    and $newsgroup_clause
    and approval_state = 'approved'
    order by release_date desc, creation_date desc"
} else {
    set query "
    select news_item_id, title, release_date, body, html_p
    from news_items
    where sysdate between release_date and expiration_date
    and $newsgroup_clause
    and approval_state = 'approved'
    order by release_date desc, creation_date desc"
}

set selection [ns_db select $db $query]

set counter 0 
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    incr counter 
    append page_content "<li>[util_AnsiDatetoPrettyDate $release_date]: "
    if { (![info exists archive_p] || $archive_p == 0) && $counter <= 3 && [string length $body] < 300 } {
	# let's display the text right here, but only offer a link
	# if there are comments.
	# set n_comments [database_to_tcl_string $db_sub "select count(*) from general_comments where on_what_id = $news_item_id and on_which_table = 'news_items'"]
	# if { $n_comments > 0 } {
	    # just do the usual thing
	    append page_content "<a href=\"item.tcl?[export_url_scope_vars news_item_id]\">$title</a>\n"
	# } else {
	#   append page_content "$title\n"
	#}
	append page_content "<blockquote>\n[util_maybe_convert_to_html $body $html_p]
	</blockquote>\n"
    } else {
	append page_content "<a href=\"item.tcl?[export_url_scope_vars news_item_id]\">$title</a>\n"
    }
}

if { $counter == 0 } {
    append page_content "no items found"
}

if { [ad_parameter ApprovalPolicy news] == "open"} {
    append page_content "<p>\n<li><a href=\"post-new.tcl?[export_url_scope_vars]\">post an item</a>\n"
} elseif { [ad_parameter ApprovalPolicy news] == "wait"} {
    append page_content "<p>\n<li><a href=\"post-new.tcl?[export_url_scope_vars]\">suggest an item</a>\n"
}

append page_content "
</ul>

"

if { ![info exists archive_p] || $archive_p == 0 } {
    append page_content "If you're looking for an old news article, check
<a href=\"index.tcl?[export_url_scope_vars]&archive_p=1\">the archives</a>."
} else {
    append page_content "You can 
<a href=\"index.tcl?[export_url_scope_vars]\">return to current messages</a> now."
}


append page_content "

[ad_scope_footer]
"

ns_db releasehandle $db
ns_db releasehandle $db_sub

ns_return 200 text/html $page_content
