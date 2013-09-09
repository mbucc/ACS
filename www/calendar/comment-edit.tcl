# www/calendar/comment-edit.tcl
ad_page_contract {
    Displays a General Comment on a calendar item for editing
    
    Number of queries: 1
    
    @author Philip Greenspun (philg@mit.edu)
    @author Sarah Ahmed (ahmeds@arsdigita.com)
    @creation-date 1998-11-18
    @cvs-id comment-edit.tcl,v 3.2.6.5 2000/09/22 01:37:04 kevin Exp
    @last-modified 2000-07-12
    @last-modified-by Michael Shurpik (mshurpik@arsdigita.com)
} {
    comment_id:integer
    {scope public}
    {user_id ""}
    {group_id ""}
    {on_what_id ""}
    {on_which_group ""}
}

## Original Comments:

# comment-edit.tcl,v 3.2.6.5 2000/09/22 01:37:04 kevin Exp
# File:     /calendar/comment-edit.tcl
# Date:     1998-11-18
# Contact:  philg@mit.edu, ahmeds@arsdigita.com
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

## Original set_form comments:

# comment_id
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)


if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}


ad_scope_error_check


ad_scope_authorize $scope all group_member registered

set query_get_comment  "
select gc.comment_id, gc.content, gc.html_p as comment_html_p, 
gc.user_id as comment_user_id, c.title, c.body, 
c.calendar_id, c.html_p as calendar_html_p
from general_comments gc, calendar c
where comment_id = :comment_id
and c.calendar_id = gc.on_what_id"

## Check if the comment exists
if { ![db_0or1row get_comment $query_get_comment] } {

    ad_scope_return_error "Can't find comment" "Can't find comment #$comment_id"
    return
    
}


db_release_unused_handles

#check for the user cookie
set user_id [ad_get_user_id]

# check to see if ther user was the original poster
if {$user_id != $comment_user_id} {
    ad_scope_return_complaint 1 "<li>You cannot edit this entry because you did not post it"
    return
}


set page_content "
[ad_scope_header "Edit comment on $title"]
<h2>Edit comment </h2>
on <A HREF=\"item?[export_url_scope_vars calendar_id]\">$title</a>
<hr>
[ad_scope_navbar]

<blockquote>
[util_maybe_convert_to_html $body $calendar_html_p]
<form action=comment-edit-2 method=post>
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

doc_return  200 text/html $page_content

## END FILE comment-edit.tcl
