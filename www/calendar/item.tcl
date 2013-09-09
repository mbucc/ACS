# www/calendar/item.tcl
ad_page_contract {
    @author Philip Greenspun (philg@mit.edu)
    @author Sarah Ahmed (ahmeds@arsdigita.com)
    @creation-date 1998-11-18
    @cvs-id item.tcl,v 3.3.2.9 2000/09/22 01:37:05 kevin Exp

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



ad_scope_error_check

set user_id [ad_scope_authorize $scope all group_member registered]



set query_item "
select c.title, c.body, c.html_p, 
c.start_date, c.end_date, 
c.event_url, c.event_email, c.creation_user, 
u.first_names, u.last_name
from calendar c, users u, calendar_categories cc
where calendar_id = :calendar_id
and c.approved_p = 't'
and u.user_id = c.creation_user
and c.category_id=cc.category_id
and [ad_scope_sql cc]
"

## Make sure this calendar_id exists
## This is also the error message that will be returned if you attempt to access
## someone's private calendar item
if {![db_0or1row item $query_item]} {

    ad_scope_return_error "
    Can't find calendar item" "Can't find calendar item $calendar_id"
    return

} 




set page_content "
[ad_scope_header "$title"]
[ad_scope_page_title $title]
[ad_scope_context_bar_ws_or_index [list "index.tcl?[export_url_scope_vars]" [ad_parameter SystemName calendar "Calendar"]] "One Item"]

<hr>
[ad_scope_navbar]

<blockquote>
[util_maybe_convert_to_html $body $html_p]
</blockquote>

<ul>
<li>
"


if { $start_date == $end_date } {
    append page_content "Date:  [util_AnsiDatetoPrettyDate $start_date]\n"
} else {
    append page_content "Dates:  [util_AnsiDatetoPrettyDate $start_date] through [util_AnsiDatetoPrettyDate $end_date]\n"
}


if ![empty_string_p $event_url] {
    append page_content "<li>Web: <a href=\"$event_url\">$event_url</a>\n"
}


if ![empty_string_p $event_email] {
    append page_content "<li>Email: <a href=\"mailto:$event_email\">$event_email</a>\n"
}

append page_content "</ul>

Contributed by <a href=\"/shared/community-member?[export_url_scope_vars]&user_id=$creation_user\">$first_names $last_name</a>.

"



set query_comments "
select comment_id, content, 
comment_date, first_names || ' ' || last_name as commenter_name, 
users.user_id as comment_user_id, html_p as comment_html_p 
from general_comments, users
where on_what_id= :calendar_id 
and on_which_table = 'calendar'
and general_comments.approved_p = 't'
and general_comments.user_id = users.user_id
"

# see if there are any comments on this item
db_foreach comments $query_comments {
    
    set first_iteration_p 1
    
    if $first_iteration_p {
	append page_content "<h4>Comments</h4>\n"
	set first_iteration_p 0
    }
    
    append page_content "<blockquote>\n[util_maybe_convert_to_html $content $comment_html_p]\n"
    
    # if the user posted the comment, they are allowed to edit it
    if {$user_id == $comment_user_id} {
        append page_content "<br><br>-- you <A HREF=\"comment-edit?[export_url_scope_vars]&comment_id=$comment_id\">(edit your comment)</a>"
    } else {
	append page_content "<br><br>-- <a href=\"/shared/community-member?[export_url_scope_vars]&user_id=$comment_user_id\">$commenter_name</a>"
    }
    append page_content "</blockquote>"
}




if { [ad_parameter SolicitCommentsP calendar] == 1 } {

    append page_content "
    <center>
    <A HREF=\"comment-add?[export_url_scope_vars]&calendar_id=$calendar_id\">Add a comment</a>
    </center>
    "
}

append page_content "
[ad_scope_footer]
"

doc_return  200 text/html $page_content

## END FILE item.tcl















