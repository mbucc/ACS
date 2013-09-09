# /www/news/index.tcl
#

ad_page_contract {
    news main page

    @author jkoontz@arsdigita.com
    @creation-date March 8, 2000
    @cvs-id index.tcl,v 3.7.2.11 2000/09/22 01:38:56 kevin Exp

    Note: if page is accessed through /groups pages then group_id and 
    group_vars_set are already set up in the environment by the 
    ug_serve_section. group_vars_set contains group related variables
    (group_id, group_name, group_short_name, group_admin_email, 
    group_public_url, group_admin_url, group_public_root_url,
    group_admin_root_url, group_type_url_p, group_context_bar_list and
    group_navbar_list)
} {
    {archive_p 0}
    scope:optional
    user_id:optional,integer
    group_id:optional,integer
    on_which_group:optional,integer
    on_what_id:optional,integer
}


ad_scope_error_check


# inappropriate use of scoping by me (ashah@arsdigita.com)
# I am setting user_id from session not from URL vars, but
# it is ok because there is no personal news, we
# just need to know if user is logged in.
# updated paul@arsdigita.com 9 July 2000, handle checks in ad_page_contract
if { ![info exists group_id] } {
    set group_id 0
    set user_id [ad_get_user_id]
} elseif { ![info exists user_id] } {
    set user_id 0
}

if { $archive_p } {
    set page_title "News Archives"
} else {
    set page_title "News"
}

proc post_new_link {} {
    if { [ad_parameter ApprovalPolicy news] == "open"} {
	return "<li><p><a href=\"post-new?[export_url_vars]\">post an item</a></p>"
    } elseif { [ad_parameter ApprovalPolicy news] == "wait"} {
	return "<li><p><a href=\"post-new?[export_url_vars]\">suggest an item</a></p>"
    }
}


ad_scope_authorize $scope all group_member none

append page_content "[ad_scope_header $page_title]"

if { $scope=="public" } {
    append page_content "
    [ad_decorate_top "<h2>$page_title</h2>[ad_scope_context_bar_ws_or_index "News"]" \
	    [ad_parameter IndexPageDecoration news]]
    "
} else {
    append page_content "
    [ad_scope_page_title $page_title]
    [ad_scope_context_bar_ws_or_index "News"]
    "
}

append page_content "
<hr>
[ad_scope_navbar]
<ul>
"


# Create a clause for returning the postings for relevant groups
set newsgroup_clause "(newsgroup_id = [join [news_newsgroup_id_list $user_id $group_id] " or newsgroup_id = "])"

if { !$archive_p } {
    set query "
    select news_item_id, title, release_date, body, html_p
    from news_items
    where sysdate between release_date and expiration_date
    and $newsgroup_clause
    and approval_state = 'approved'
    order by release_date desc, creation_date desc"
} else {
    set query "
    select news_item_id, title, release_date, body, html_p
    from news_items
    where sysdate > expiration_date
    and $newsgroup_clause
    and approval_state = 'approved'
    order by release_date desc, creation_date desc"
}


set counter 0
db_foreach news_item_get $query {
    incr counter 
    append news_html "<li>[util_AnsiDatetoPrettyDate $release_date]: "

    # let's consider displaying the text right here, but
    # only if there aren't any comments 
    set n_comments [db_string news_commentcount_get "
    select count(*)
    from general_comments 
    where on_what_id = :news_item_id 
    and on_which_table = 'news_items'"]

    if { !$archive_p && $counter <= 3 && [string length $body] < 300 && $n_comments == 0 } {
	append news_html "<blockquote>\n[util_maybe_convert_to_html $body $html_p]"
	if [ad_parameter SolicitCommentsP news 1] {
	    set url_args_set [ns_set create url_args_set]
	    ns_set put $url_args_set on_which_table news_items
	    ns_set put $url_args_set on_what_id $news_item_id
	    ns_set put $url_args_set item $title
	    ns_set put $url_args_set module news
	    ns_set put $url_args_set return_url "/news/"
	    append news_html "<br><br><a href=\"/general-comments/comment-add?[export_ns_set_vars url "" $url_args_set]\">comment</a>"
	}
	append news_html "</blockquote>\n"
    } else {
	append news_html "<a href=\"item?[export_url_vars news_item_id]\">$title</a>\n"
    }
}
db_release_unused_handles


if { $counter == 0 } {
    append news_html "no items found"
}

# If there are lots of news, we add the Post News link to the top, too.
set min_number [ad_parameter MinNumberForTopLink news]
if { ![empty_string_p $min_number] && $counter >= $min_number } {
    append page_content "[post_new_link]"
}

append page_content "
$news_html
<p>[post_new_link]

</ul>

"

if { !$archive_p } {
    append page_content "If you're looking for an old news article, check
<a href=\"?archive_p=1\">the archives</a>."
} else {
    append page_content "You can 
<a href=\"\">return to current messages</a> now."
}


append page_content "[ad_scope_footer]"



doc_return  200 text/html $page_content
