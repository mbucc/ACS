# $Id: item.tcl,v 3.0 2000/02/06 03:36:12 ron Exp $
# File:     /calendar/admin/item.tcl
# Date:     1998-11-18
# Contact:  philg@mit.edu, ahmeds@arsdigita.com
# Purpose:  shows one calendar item
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

set_the_usual_form_variables 0
# calendar_id
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)
# maybe contact_info_only, maybe order_by

ad_scope_error_check
set db [ns_db gethandle]
ad_scope_authorize $db $scope admin group_admin none

set return_url [ns_urlencode [ns_conn url]?calendar_id=$calendar_id]

set selection [ns_db 0or1row $db "
select title, body, html_p, calendar.approved_p, start_date, end_date, expiration_date, category_id, event_url, event_email, creation_user, creation_date, first_names, last_name
from calendar, users 
where calendar_id = $calendar_id
and users.user_id = creation_user"]

if { $selection == "" } {
    ad_scope_return_error "Can't find calendar item" "Can't find news item $calendar_id" $db
    return
}

set_variables_after_query

set category [database_to_tcl_string $db "
select category 
from calendar_categories
where category_id = $category_id "]

ReturnHeaders

ns_write "
[ad_scope_admin_header "$title" $db]
[ad_scope_admin_page_title "$title" $db ]
[ad_scope_admin_context_bar [list "index.tcl?[export_url_scope_vars]" "Calendar"] "One Item"]

<hr>

<ul>
<li>Category: $category (<A HREF=\"item-category-change.tcl?[export_url_scope_vars calendar_id]\">Change</a>)

<p>
<li>Status:  
"

if {$approved_p == "t" } {
    ns_write "Approved (<a href=\"toggle-approved-p.tcl?[export_url_scope_vars calendar_id]\">Revoke</a>)"
} else {
    ns_write "<font color=red>Awaiting approval</font> (<a href=\"toggle-approved-p.tcl?[export_url_scope_vars calendar_id]\">Approve</a>)"
}

ns_write "
<li>Start Date: [util_AnsiDatetoPrettyDate $start_date]
<li>End Date: [util_AnsiDatetoPrettyDate $end_date]
<li>Expires: [util_AnsiDatetoPrettyDate $expiration_date]
<li>Submitted by: <a href=\"/admin/users/one.tcl?[export_url_scope_vars]&user_id=$creation_user\">$first_names $last_name</a>"


if ![empty_string_p $event_url] {
    ns_write "<li>Web: <a href=\"$event_url\">$event_url</a>\n"
}

if ![empty_string_p $event_email] {
    ns_write "<li>Email: <a href=\"mailto:$event_email\">$event_email</a>\n"
}

ns_write "</ul>

<h4>Body</h4>

<blockquote>
[util_maybe_convert_to_html $body $html_p]
<br>
<br>
<form action=post-edit.tcl method=get>
[export_form_scope_vars]
<input type=hidden name=calendar_id value=\"$calendar_id\">
<input type=submit name=submit value=\"Edit\">
</form>

</blockquote>

"

# see if there are any comments on this item
set selection [ns_db select $db "
select comment_id, content, comment_date, first_names || ' ' || last_name as commenter_name, users.user_id as comment_user_id, html_p as comment_html_p, general_comments.approved_p as comment_approved_p from
general_comments, users
where on_what_id = $calendar_id 
and on_which_table = 'calendar'
and general_comments.user_id = users.user_id"]

set first_iteration_p 1
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    if $first_iteration_p {
	ns_write "<h4>Comments</h4>\n"
	set first_iteration_p 0
    }
    ns_write "<table width=90%>
<tr><td><blockquote>\n[util_maybe_convert_to_html $content $comment_html_p]\n"
    ns_write "<br><br>-- <a href=\"/admin/users/1.tcl?[export_url_scope_vars]&user_id=$comment_user_id\">$commenter_name</a>"
    ns_write "</blockquote>
</td>
<td align=right>"

    # print out the approval status if we are using the approval system
    if { [ad_parameter CommentApprovalPolicy calendar] != "open"} {
	if {$comment_approved_p == "t" } {
	    ns_write "<a href=\"/admin/general-comments/toggle-approved-p.tcl?[export_url_scope_vars comment_id return_url]\">Revoke approval</a>"
	} else {
	    ns_write "<a href=\"/admin/general-comments/toggle-approved-p.tcl?[export_url_scope_vars comment_id return_url]\">Approve</a>"
	}
	    ns_write "<br>"
    }

ns_write "<a href=\"/admin/general-comments/edit.tcl?[export_url_scope_vars comment_id]\" target=working>edit</a>
<br>
<a href=\"/admin/general-comments/delete.tcl?[export_url_scope_vars comment_id]\" target=working>delete</a>
</td>
</table>"
}

ns_write "[ad_scope_admin_footer]"

