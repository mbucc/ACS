# www/admin/calendar/item.tcl
ad_page_contract {
    Displays a calendar item

    Number of queries: 3 or 4

    @author Philip Greenspun (philg@mit.edu)
    @author Sarah Ahmed (ahmeds@arsdigita.com)
    @creation-date 1998-11-18
    @cvs-id item.tcl,v 3.3.2.5 2000/09/22 01:34:26 kevin Exp
    
} {
    calendar_id:naturalnum
}



set return_url [ns_urlencode [ns_conn url]?calendar_id=$calendar_id]




set query_item "
select title, body, html_p, calendar.approved_p, start_date, end_date, expiration_date, 
category_id, event_url, event_email, creation_user, creation_date, first_names, last_name
from calendar, users 
where calendar_id = :calendar_id
and users.user_id = creation_user"

if { ![db_0or1row item $query_item] } {

    ad_return_error "Can't find calendar item" "Can't find calendar item $calendar_id"
    return
}

set query_category "
select category 
from calendar_categories
where category_id = :category_id "

set category [db_string category $query_category] 

set query_scope_group_id "
select scope, group_id
from calendar_categories
where category_id = :category_id "

db_1row scope_group_id $query_scope_group_id


switch $scope {

    group {
    
	db_1row short_name "select short_name 
	from user_groups 
	where group_id = :group_id"
	
	set admin_url_string "/[ad_parameter GroupsDirectory ug]/
	[ad_parameter GroupsAdminDirectory ug]/[ad_urlencode $short_name]/calendar/item.tcl?calendar_id=$calendar_id&scope=$scope&group_id=$group_id"
	
	set userpage_url_string "/[ad_parameter GroupsDirectory ug]/[ad_urlencode $short_name]/calendar/item.tcl?calendar_id=$calendar_id&scope=$scope&group_id=$group_id" 
	
    }
    
    public {
	
	set admin_url_string "/calendar/admin/item.tcl?calendar_id=$calendar_id&scope=$scope"
	set userpage_url_string "/calendar/item.tcl?calendar_id=$calendar_id&scope=$scope"

    }
    
    user {

	set admin_url_string "/calendar/admin/item.tcl?calendar_id=$calendar_id&scope=$scope"
	set userpage_url_string "/calendar/item.tcl?calendar_id=$calendar_id&scope=$scope"
    }

    default {

	set admin_url_string "/calendar/admin/item.tcl?calendar_id=$calendar_id&scope=$scope"
	set userpage_url_string "/calendar/item.tcl?calendar_id=$calendar_id&scope=$scope"
    }
}


set page_content "
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

    append page_content "Approved (<a href=\"toggle-approved-p?calendar_id=$calendar_id\">Revoke</a>)"

} else {

    append page_content "<font color=red>Awaiting approval</font> (<a href=\"toggle-approved-p?calendar_id=$calendar_id\">Approve</a>)"
}


append page_content "
<li>Start Date: [util_AnsiDatetoPrettyDate $start_date]
<li>End Date: [util_AnsiDatetoPrettyDate $end_date]
<li>Expires: [util_AnsiDatetoPrettyDate $expiration_date]
<li>Submitted by: <a href=\"/admin/users/one?user_id=$creation_user\">$first_names $last_name</a>"


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
<input type=hidden name=calendar_id value=\"$calendar_id\">
<input type=submit name=submit value=\"Edit\">
</form>

</blockquote>

"

# see if there are any comments on this item

set query_comments "select comment_id, content, comment_date, first_names || ' ' || last_name as commenter_name, 
users.user_id as comment_user_id, html_p as comment_html_p, general_comments.approved_p as comment_approved_p 
from general_comments, users
where on_what_id = :calendar_id 
and on_which_table = 'calendar'
and general_comments.user_id = users.user_id"

set first_iteration_p 1

db_foreach comments $query_comments {

    if $first_iteration_p {

	append page_content "<h4>Comments</h4>\n"
	set first_iteration_p 0
    }

    append page_content "<table width=90%>
    <tr><td><blockquote>\n[util_maybe_convert_to_html $content $comment_html_p]\n"
    append page_content "<br><br>-- <a href=\"/admin/users/one?user_id=$comment_user_id\">$commenter_name</a>"
    append page_content "</blockquote>
    </td>
    <td align=right>"

    #we only want the following if we are allowing comments:
    
    # print out the approval status if we are using the approval system
    if { [ad_parameter CommentApprovalPolicy calendar] != "open"} {

	if {$comment_approved_p == "t" } {

	    append page_content "<a href=\"/admin/general-comments/toggle-approved-p?comment_id=$comment_id&return_url=$return_url\">Revoke approval</a>"

	} else {

	    append page_content "<a href=\"/admin/general-comments/toggle-approved-p?comment_id=$comment_id&return_url=$return_url\">Approve</a>"
	}

	append page_content "<br>"
    }

    append page_content "<a href=\"/admin/general-comments/edit?comment_id=$comment_id\" target=working>edit</a>
    <br>
    <a href=\"/admin/general-comments/delete?comment_id=$comment_id\" target=working>delete</a>
    </td>
    </table>"
}

append page_content "[ad_admin_footer]"

doc_return  200 text/html $page_content

## END FILE item.tcl
