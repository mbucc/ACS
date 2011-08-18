# $Id: item.tcl,v 3.1 2000/03/11 09:02:04 aileen Exp $
# File:     /calendar/item.tcl
# Date:     1998-11-18
# Contact:  philg@mit.edu, ahmeds@arsdigita.com
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

set_the_usual_form_variables 0
# calendar_id
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)

ad_scope_error_check

set db [ns_db gethandle]


set selection [ns_db 0or1row $db "
select c.*, first_names, last_name
from calendar c, users u
where calendar_id = $calendar_id
and u.user_id = c.creation_user"]

if { $selection == "" } {
    ad_scope_return_error "Can't find calendar item" "Can't find calendar item $calendar_id " $db
    return
}

set_variables_after_query

set user_id [ad_scope_authorize $db $scope all group_member registered]

ReturnHeaders

ns_write "
[ad_scope_header "$title" $db]
[ad_scope_page_title $title $db]
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
    ns_write "Date:  [util_AnsiDatetoPrettyDate $start_date]\n"
} else {
    ns_write "Dates:  [util_AnsiDatetoPrettyDate $start_date] through [util_AnsiDatetoPrettyDate $end_date]\n"
}

if ![empty_string_p $event_url] {
    ns_write "<li>Web: <a href=\"$event_url\">$event_url</a>\n"
}

if ![empty_string_p $event_email] {
    ns_write "<li>Email: <a href=\"mailto:$event_email\">$event_email</a>\n"
}

ns_write "</ul>

Contributed by <a href=\"/shared/community-member.tcl?[export_url_scope_vars]&user_id=$creation_user\">$first_names $last_name</a>.

"

# see if there are any comments on this item
set selection [ns_db select $db "
select comment_id, content, comment_date, first_names || ' ' || last_name as commenter_name, users.user_id as comment_user_id, html_p as comment_html_p from
general_comments, users
where on_what_id= $calendar_id 
and on_which_table = 'calendar'
and general_comments.approved_p = 't'
and general_comments.user_id = users.user_id"]

set first_iteration_p 1
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    if $first_iteration_p {
	ns_write "<h4>Comments</h4>\n"
	set first_iteration_p 0
    }
    ns_write "<blockquote>\n[util_maybe_convert_to_html $content $comment_html_p]\n"

    # if the user posted the comment, they are allowed to edit it
    if {$user_id == $comment_user_id} {
        ns_write "<br><br>-- you <A HREF=\"comment-edit.tcl?[export_url_scope_vars]&comment_id=$comment_id\">(edit your comment)</a>"
    } else {
	ns_write "<br><br>-- <a href=\"/shared/community-member.tcl?[export_url_scope_vars]&user_id=$comment_user_id\">$commenter_name</a>"
    }
    ns_write "</blockquote>"
}

if { [ad_parameter SolicitCommentsP calendar] == 1 } {

    ns_write "
<center>
<A HREF=\"comment-add.tcl?[export_url_scope_vars]&calendar_id=$calendar_id\">Add a comment</a>
</center>
"
}

ns_write "
[ad_scope_footer]
"