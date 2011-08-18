#
# /www/news/admin/item.tcl
#
# news item page
#
# Author: jkoontz@arsdigita.com March 8, 2000
#
# $Id: item.tcl,v 3.1.2.2 2000/03/16 23:07:21 jkoontz Exp $

# Note: if page is accessed through /groups pages then group_id and 
# group_vars_set are already set up in the environment by the 
# ug_serve_section. group_vars_set contains group related variables
# (group_id, group_name, group_short_name, group_admin_email, 
# group_public_url, group_admin_url, group_public_root_url,
# group_admin_root_url, group_type_url_p, group_context_bar_list and
# group_navbar_list)

set_the_usual_form_variables
# news_item_id
# maybe scope, maybe scope related variables (group_id, public)
# maybe contact_info_only, maybe order_by

ad_scope_error_check
set db [ns_db gethandle]
news_admin_authorize $db $news_item_id

set return_url "[ns_conn url]?news_item_id=$news_item_id"

set selection [ns_db 0or1row $db "
select n.title, n.body, html_p, n.approval_state, n.release_date, 
  n.expiration_date, n.creation_user, n.creation_date, first_names, last_name
from news_items n, users u
where news_item_id = $news_item_id
and u.user_id = n.creation_user"]

if { $selection == "" } {
    ad_scope_return_error "Can't find news item" "Can't find news item $news_item_id" $db
    return
}

set_variables_after_query

append page_content "

[ad_scope_admin_header "$title" $db ]
[ad_scope_admin_page_title "$title" $db ]
[ad_scope_admin_context_bar [list "index.tcl?[export_url_scope_vars]" "News"] "One Item"]

<hr>

<ul>
<li>Status:  
"

if { [string match $approval_state "approved"] } {
    append page_content "Approved (<a href=\"toggle-approved-p.tcl?[export_url_scope_vars news_item_id]\">Revoke</a>)"
} else {
    append page_content "<font color=red>Awaiting approval</font> (<a href=\"toggle-approved-p.tcl?[export_url_scope_vars news_item_id]\">Approve</a>)"
}

append page_content "
<li>Release Date: [util_AnsiDatetoPrettyDate $release_date]
<li>Expires: [util_AnsiDatetoPrettyDate $expiration_date]
<li>Submitted by: [ad_decode $scope public "<a href=\"/admin/users/one.tcl?[export_url_scope_vars]&user_id=$creation_user\">$first_names $last_name</a>" group "<a href=\"/shared/community-member.tcl?[export_url_scope_vars]&user_id=$creation_user\">$first_names $last_name</a>" unknown]
</ul>

<h4>Body</h4>

<blockquote>
[util_maybe_convert_to_html $body $html_p]
<br>
<br>
<form action=post-edit.tcl method=get>
[export_form_scope_vars]
<input type=hidden name=news_item_id value=\"$news_item_id\">
<input type=submit name=submit value=\"Edit\">
</form>

</blockquote>

[news_item_comments $db $news_item_id]

[ad_scope_admin_footer]
"

# [ad_general_comments_list $db $news_item_id news_items $title news]

ns_db releasehandle $db

ns_return 200 text/html $page_content
