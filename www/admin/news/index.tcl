#
# /www/admin/news/index.tcl
#
# main admin news page
#
# Author: jkoontz@arsdigita.com March 8, 2000
#
# $Id: index.tcl,v 3.1 2000/03/10 23:45:54 jkoontz Exp $

set db [ns_db gethandle]

append page_content "
[ad_admin_header "News Administration"]
<h2>News Administration</h2>
[ad_admin_context_bar "News"]
<hr>
<ul>
"

set selection [ns_db select $db "
select n.title, n.news_item_id, n.approval_state, n.release_date, ng.group_id,
 expired_p(n.expiration_date) as expired_p, 
 decode(ng.scope, 'all_users', 'All users', 'registered_users', 'All registered users', 
        'public', 'Public', 'group', 'Group') as scope, 
 ug.group_name, ng.newsgroup_id
from news_items n, newsgroups ng, user_groups ug
where n.newsgroup_id = ng.newsgroup_id
and ng.group_id = ug.group_id(+)
order by ng.newsgroup_id, expired_p, release_date desc"]

set counter 0 
set old_newsgroup_id ""
set displayed_all_users_p 0
set displayed_registered_users_p 0
set expired_p_headline_written_p 0
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    incr counter

    # Check if the special newsgroups have been displayed
    if { [string match $scope "all_users"] } {
	set displayed_all_users_p 1
    }
    if { [string match $scope "registered_users"] } {
	set displayed_registered_users_p 1
    }

    # if we are displaying the public newsgroup, show a link 
    # for the special newsgroups not seen.
    if { [string match $scope "public"] } {
	if { !$displayed_all_users_p } {
	    append page_content "</ul><h4>All users</h4><ul>
            <li><a href=\"post-new.tcl?scope=all_users\">add an item</a>"
	}
	if { !$displayed_registered_users_p } {
	    append page_content "</ul><h4>All registered users</h4><ul>
            <li><a href=\"post-new.tcl?scope=registered_users\">add an item</a>"
	}
	set displayed_all_users_p 1
	set displayed_registered_users_p 1
    }

    if { $old_newsgroup_id != $newsgroup_id } { 
	append page_content "</ul><h4>$scope $group_name</h4><ul>
	<li><a href=\"post-new.tcl?[export_url_vars scope group_id]\">add an item</a>
	<P>
	"
	set old_newsgroup_id $newsgroup_id
	set expired_p_headline_written_p 0
    }

    if { $expired_p == "t" && !$expired_p_headline_written_p } {
	append page_content "<p><b>Expired News Items</b>\n"
	set expired_p_headline_written_p 1
    }
    append page_content "<li>[util_AnsiDatetoPrettyDate $release_date]: <a href=\"item.tcl?[export_url_vars news_item_id]\">$title</a>"
    if { ![string match $approval_state "approved"] } {
	append page_content "&nbsp; <font color=red>not approved</font>"
    }
    append page_content "\n"
}

append page_content "

</ul>

[ad_admin_footer]
"

ns_return 200 text/html $page_content
