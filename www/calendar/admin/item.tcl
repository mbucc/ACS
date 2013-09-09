# www/calendar/admin/item.tcl
ad_page_contract {
    Displays a calendar event

    Number of queries: 3

    @author Philip Greenspun (philg@mit.edu)
    @author Sarah Ahmed (ahmeds@arsdigita.com)
    @creation-date 1998-11-18
    @cvs-id item.tcl,v 3.2.2.6 2000/09/22 01:37:06 kevin Exp
    
} {
    calendar_id:naturalnum
    {scope public}
    {user_id:naturalnum ""}
    {group_id:naturalnum ""}
    {on_what_id:naturalnum ""}
    {on_which_group:naturalnum ""}
}

# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

# calendar_id
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)
# maybe contact_info_only, maybe order_by


ad_scope_error_check

ad_scope_authorize $scope admin group_admin none

set return_url [ns_urlencode [ns_conn url]?calendar_id=$calendar_id]

set query_get_item "select title, body, html_p, calendar.approved_p, 
start_date, end_date, expiration_date, category_id, event_url, 
event_email, creation_user, creation_date, first_names, last_name
from calendar, users 
where calendar_id = :calendar_id
and users.user_id = creation_user"

if { ![db_0or1row get_item $query_get_item] } {

    ad_scope_return_error "Can't find calendar event" "Can't find event $calendar_id"
    return
}

set query_category "select category 
from calendar_categories
where category_id = :category_id"

set category [db_string category $query_category]



set page_content "
[ad_scope_admin_header "$title"]
[ad_scope_admin_page_title "$title"]
[ad_scope_admin_context_bar [list "index.tcl?[export_url_scope_vars]" "Calendar"] "One Event"]

<hr>

<ul>
<li>Category: $category (<A HREF=\"item-category-change?[export_url_scope_vars calendar_id]\">Change</a>)

<p>
<li>Status:  
"

if {$approved_p == "t" } {
    append page_content "Approved (<a href=\"toggle-approved-p?[export_url_scope_vars calendar_id]\">Revoke</a>)"
} else {
    append page_content "<font color=red>Awaiting approval</font> (<a href=\"toggle-approved-p?[export_url_scope_vars calendar_id]\">Approve</a>)"
}

append page_content "
<li>Start Date: [util_AnsiDatetoPrettyDate $start_date]
<li>End Date: [util_AnsiDatetoPrettyDate $end_date]
<li>Expires: [util_AnsiDatetoPrettyDate $expiration_date]
<li>Submitted by: <a href=\"/admin/users/one?[export_url_scope_vars]&user_id=$creation_user\">$first_names $last_name</a>"

if ![empty_string_p $event_url] {
    append page_content "<li>Web: <a href=\"$event_url\">$event_url</a>\n"
}

if ![empty_string_p $event_email] {
    append page_content "<li>Email: <a href=\"mailto:$event_email\">$event_email</a>\n"
}

append page_content "</ul>

<h4>Body</h4>

<blockquote>
[util_maybe_convert_to_html $body $html_p]
<br>
<br>
<form action=post-edit method=get>
[export_form_scope_vars]
<input type=hidden name=calendar_id value=\"$calendar_id\">
<input type=submit name=submit value=\"Edit\">
</form>

</blockquote>

"

# see if there are any comments on this event
set query_comments_admin "
select comment_id, content, comment_date, first_names || ' ' || last_name as commenter_name, 
users.user_id as comment_user_id, html_p as comment_html_p, 
general_comments.approved_p as comment_approved_p from
general_comments, users
where on_what_id = :calendar_id 
and on_which_table = 'calendar'
and general_comments.user_id = users.user_id"

set first_iteration_p 1

db_foreach comments_admin $query_comments_admin {

    if $first_iteration_p {
	append page_content "<h4>Comments</h4>\n"
	set first_iteration_p 0
    }

    append page_content "<table width=90%>
    <tr><td><blockquote>\n[util_maybe_convert_to_html $content $comment_html_p]\n"

    append page_content "<br><br>-- <a href=\"/admin/users/1?[export_url_scope_vars]&user_id=$comment_user_id\">$commenter_name</a>"
    append page_content "</blockquote>
    </td>
    <td align=right>"

    # print out the approval status if we are using the approval system
    if { [ad_parameter CommentApprovalPolicy calendar] != "open"} {
	
	if {$comment_approved_p == "t" } {
	    append page_content "<a href=\"/admin/general-comments/toggle-approved-p?[export_url_scope_vars comment_id return_url]\">Revoke approval</a>"
	} else {
	    append page_content "<a href=\"/admin/general-comments/toggle-approved-p?[export_url_scope_vars comment_id return_url]\">Approve</a>"
	}
	    append page_content "<br>"
    }

db_release_unused_handles

append page_content "<a href=\"/admin/general-comments/edit?[export_url_scope_vars comment_id]\" target=working>edit</a>
<br>
<a href=\"/admin/general-comments/delete?[export_url_scope_vars comment_id]\" target=working>delete</a>
</td>
</table>"
}

append page_content "[ad_scope_admin_footer]"


doc_return  200 text/html $page_content

## END FILE item.tcl
