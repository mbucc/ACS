# /www/news/admin/index.tcl
#

ad_page_contract {
    news main admin page

    @author jkoontz@arsdigita.com
    @creation-date March 8, 2000
    @cvs-id index.tcl,v 3.4.2.10 2000/09/22 01:38:58 kevin Exp

    Note: if page is accessed through /groups pages then group_id and 
    group_vars_set are already set up in the environment by the 
    ug_serve_section. group_vars_set contains group related variables (group_id, 
    group_name, group_short_name, group_admin_email, group_public_url, 
    group_admin_url, group_public_root_url, group_admin_root_url, 
    group_type_url_p, group_context_bar_list and group_navbar_list)
} {
    archive_p:optional
    scope:optional
    {user_id:integer "0"}
    {group_id:integer "0"}
    on_which_group:integer,optional
    on_what_id:integer,optional
}


ad_scope_error_check

ad_scope_authorize $scope admin group_member none

set page_content "
[ad_scope_admin_header "News Administration"]
[ad_scope_admin_page_title "News Administration"]
[ad_scope_admin_context_bar "News"]
<hr>
<ul>
"

# Create a clause for returning the postings for relevant groups
set newsgroup_clause "(newsgroup_id = [join [news_newsgroup_id_list $user_id $group_id] " or newsgroup_id = "])"

set sql "
select news_item_id,
       title,
       approval_state,
       release_date,
       expired_p(expiration_date) as expired_p
from news_items
where $newsgroup_clause
order by expired_p, creation_date desc"


set counter 0 
set expired_p_headline_written_p 0
db_foreach news_item_get $sql {
    incr counter 
    if { $expired_p == "t" && !$expired_p_headline_written_p } {
	append page_content "<h4>Expired News Items</h4>\n"
	set expired_p_headline_written_p 1
    }
    append page_content "<li>[util_AnsiDatetoPrettyDate $release_date]: <a href=\"item?[export_url_vars news_item_id]\">$title</a>"
    if { ![string match $approval_state "approved"] } {
	append page_content "&nbsp; <font color=red>not approved</font>"
    }
    append page_content "\n"
}
db_release_unused_handles


append page_content "

<P>

<li><a href=\"post-new\">add an item</a>

</ul>

[ad_scope_admin_footer]
"



doc_return  200 text/html $page_content
