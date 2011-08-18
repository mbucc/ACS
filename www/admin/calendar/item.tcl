# $Id: item.tcl,v 3.1 2000/03/10 21:50:40 jkoontz Exp $
# File:     admin/calendar/item.tcl
# Date:     1998-11-18
# Contact:  philg@mit.edu, ahmeds@arsdigita.com
# Purpose:  shows one calendar item  

set_the_usual_form_variables

# calendar_id

set return_url [ns_urlencode [ns_conn url]?calendar_id=$calendar_id]

set db [ns_db gethandle]

set selection [ns_db 0or1row $db "
select title, body, html_p, calendar.approved_p, start_date, end_date, expiration_date, category_id,event_url, event_email, creation_user, creation_date, first_names, last_name
from calendar, users 
where calendar_id = $calendar_id
and users.user_id = creation_user"]

if { $selection == "" } {
    ad_return_error "Can't find calendar item" "Can't find calendar item $calendar_id"
    return
}

set_variables_after_query

set category [database_to_tcl_string $db "
select category 
from calendar_categories
where category_id = $category_id "]

set selection [ns_db 1row $db "
select scope, group_id
from calendar_categories
where category_id = $category_id "]

set_variables_after_query

if { $scope=="group" } {
    set short_name [database_to_tcl_string $db "select short_name
                                                from user_groups
                                                where group_id = $group_id"]    
}

if { $scope == "public" } {
    set admin_url_string "/calendar/admin/item.tcl?calendar_id=$calendar_id&scope=$scope"
    set userpage_url_string "/calendar/item.tcl?calendar_id=$calendar_id&scope=$scope"
} else {
    set admin_url_string "/[ad_parameter GroupsDirectory ug]/[ad_parameter GroupsAdminDirectory ug]/[ad_urlencode $short_name]/calendar/item.tcl?calendar_id=$calendar_id&scope=$scope&group_id=$group_id"
    set userpage_url_string "/[ad_parameter GroupsDirectory ug]/[ad_urlencode $short_name]/calendar/item.tcl?calendar_id=$calendar_id&scope=$scope&group_id=$group_id" 
}

ReturnHeaders

ns_write "
[ad_admin_header "$title"]
<h2>$title</h2>
[ad_admin_context_bar [list "index.tcl" "Calendar"] "One Item"]

<hr>

<table>
<tr>
 <td align=right> Maintainer Page:</td>
 <td> <a href=$admin_url_string>$admin_url_string</a></td>
</tr>
<tr>
 <td align=right>User Page:</td>
 <td> <a href=$userpage_url_string>$userpage_url_string</a></td>
</tr>
</table>

<ul>
<li>Category: $category 

<p>
<li>Status:  
"

if {$approved_p == "t" } {
    ns_write "Approved (<a href=\"toggle-approved-p.tcl?calendar_id=$calendar_id\">Revoke</a>)"
} else {
    ns_write "<font color=red>Awaiting approval</font> (<a href=\"toggle-approved-p.tcl?calendar_id=$calendar_id\">Approve</a>)"
}

ns_write "
<li>Start Date: [util_AnsiDatetoPrettyDate $start_date]
<li>End Date: [util_AnsiDatetoPrettyDate $end_date]
<li>Expires: [util_AnsiDatetoPrettyDate $expiration_date]
<li>Submitted by: <a href=\"/admin/users/one.tcl?user_id=$creation_user\">$first_names $last_name</a>"


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
<input type=hidden name=calendar_id value=\"$calendar_id\">
<input type=submit name=submit value=\"Edit\">
</form>

</blockquote>

"


# see if there are any comments on this item
set selection [ns_db select $db "select comment_id, content, comment_date, first_names || ' ' || last_name as commenter_name, users.user_id as comment_user_id, html_p as comment_html_p, general_comments.approved_p as comment_approved_p from
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
    ns_write "<br><br>-- <a href=\"/admin/users/one.tcl?user_id=$comment_user_id\">$commenter_name</a>"
    ns_write "</blockquote>
    </td>
    <td align=right>"

    #we only want the following if we are allowing comments:
    
    # print out the approval status if we are using the approval system
    if { [ad_parameter CommentApprovalPolicy calendar] != "open"} {
	if {$comment_approved_p == "t" } {
	    ns_write "<a href=\"/admin/general-comments/toggle-approved-p.tcl?comment_id=$comment_id&return_url=$return_url\">Revoke approval</a>"
	} else {
	    ns_write "<a href=\"/admin/general-comments/toggle-approved-p.tcl?comment_id=$comment_id&return_url=$return_url\">Approve</a>"
	}
	ns_write "<br>"
    }

    ns_write "<a href=\"/admin/general-comments/edit.tcl?comment_id=$comment_id\" target=working>edit</a>
<br>
<a href=\"/admin/general-comments/delete.tcl?comment_id=$comment_id\" target=working>delete</a>
</td>
</table>"
}

ns_write "[ad_admin_footer]"

