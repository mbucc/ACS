# $Id: comment-edit.tcl,v 3.1 2000/03/11 09:02:19 aileen Exp $
# File:     /calendar/comment-edit.tcl
# Date:     1998-11-18
# Contact:  philg@mit.edu, ahmeds@arsdigita.com
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set_form_variables 0
# comment_id
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)

ad_scope_error_check

set db [ns_db gethandle]
ad_scope_authorize $db $scope all group_member registered


set selection [ns_db 1row $db "
select gc.comment_id, gc.content, gc.html_p as comment_html_p, gc.user_id as comment_user_id, c.title, c.body, c.calendar_id, c.html_p as calendar_html_p
from general_comments gc, calendar c
where comment_id = $comment_id
and c.calendar_id = gc.on_what_id"]

set_variables_after_query

#check for the user cookie
set user_id [ad_get_user_id]


# check to see if ther user was the orginal poster
if {$user_id != $comment_user_id} {
    ad_scope_return_complaint 1 "<li>You can not edit this entry because you did not post it" $db
    return
}
ReturnHeaders

ns_write "
[ad_scope_header "Edit comment on $title" $db]
<h2>Edit comment </h2>
on <A HREF=\"item.tcl?[export_url_scope_vars calendar_id]\">$title</a>
<hr>
[ad_scope_navbar]

<blockquote>
[util_maybe_convert_to_html $body $calendar_html_p]
<form action=comment-edit-2.tcl method=post>
Edit your comment on the above item.<br>
<textarea name=content cols=50 rows=5 wrap=soft>[philg_quote_double_quotes $content]</textarea><br>
Text above is
<select name=html_p>
 [ad_generic_optionlist {"Plain Text" "HTML"} {"f" "t"} $comment_html_p]
</select>
<center>
<input type=submit name=submit value=\"Proceed\">
</center>
[export_form_scope_vars comment_id]
</form>
</blockquote>
[ad_scope_footer]
"

