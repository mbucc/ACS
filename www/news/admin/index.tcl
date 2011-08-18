#
# /www/news/admin/index.tcl
#
# news main admin page
#
# Author: jkoontz@arsdigita.com March 8, 2000
#
# $Id: index.tcl,v 3.2 2000/03/10 23:45:34 jkoontz Exp $

# Note: if page is accessed through /groups pages then group_id and 
# group_vars_set are already set up in the environment by the 
# ug_serve_section. group_vars_set contains group related variables (group_id, 
# group_name, group_short_name, group_admin_email, group_public_url, 
# group_admin_url, group_public_root_url, group_admin_root_url, 
# group_type_url_p, group_context_bar_list and group_navbar_list)

set_the_usual_form_variables 0
# possibly archive_p 
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)

ad_scope_error_check
set db [ns_db gethandle]
ad_scope_authorize $db $scope admin group_member none

append page_content "
[ad_scope_admin_header "News Administration" $db ]
[ad_scope_admin_page_title "News Administration" $db]
[ad_scope_admin_context_bar "News"]
<hr>
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

set selection [ns_db select $db "
select news_item_id, title, approval_state, release_date,
 expired_p(expiration_date) as expired_p
from news_items
where $newsgroup_clause
order by expired_p, creation_date desc"]

set counter 0 
set expired_p_headline_written_p 0
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    incr counter 
    if { $expired_p == "t" && !$expired_p_headline_written_p } {
	append page_content "<h4>Expired News Items</h4>\n"
	set expired_p_headline_written_p 1
    }
    append page_content "<li>[util_AnsiDatetoPrettyDate $release_date]: <a href=\"item.tcl?[export_url_scope_vars news_item_id]\">$title</a>"
    if { ![string match $approval_state "approved"] } {
	append page_content "&nbsp; <font color=red>not approved</font>"
    }
    append page_content "\n"
}

append page_content "

<P>

<li><a href=\"post-new.tcl?[export_url_scope_vars]\">add an item</a>

</ul>


[ad_scope_admin_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $page_content
