# $Id: comment-edit.tcl,v 3.0 2000/02/06 03:44:01 ron Exp $
# File:     /general-comments/comment-edit.tcl
# Date:     01/21/2000
# Contact:  philg@mit.edu, tarik@mit.edu
# Purpose:  
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set_form_variables
# comment_id, item, module, return_url

# check for the user cookie
set user_id [ad_get_user_id]
ad_maybe_redirect_for_registration

set db [ns_db gethandle]

set selection [ns_db 1row $db "select comment_id, content, general_comments.html_p as comment_html_p, general_comments.user_id as comment_user_id, one_line
from general_comments
where comment_id = $comment_id"]
set_variables_after_query

# check to see if ther user was the orginal poster
if {$user_id != $comment_user_id && ![ad_permission_p $db $module $submodule]} {
    ad_return_complaint 1 "<li>You can not edit this entry because you did not post it"
    return
}


if {[ad_parameter UseTitlesP "general-comments" 0]} {
    set title_text "Title:<br>
<input type=text name=one_line maxlenth=200 [export_form_value one_line]>
<p>
Comment:<br>
"     
} else {
    set title_text ""
}


ns_return 200 text/html "[ad_header "Edit comment on $item" ]

<h2>Edit comment on $item</h2>

[ad_context_bar_ws  [list "$return_url" $item]  "Edit comment"]

<hr>

<P>
Edit your comment.<br>

<form action=comment-edit-2.tcl method=post>
[export_form_vars comment_id module submodule return_url item]

<blockquote>

$title_text

<textarea name=content cols=50 rows=5 wrap=soft>[ns_quotehtml $content]</textarea><br>
Text above is
<select name=html_p>[html_select_value_options [list [list "f" "Plain Text" ] [list  "t" "HTML" ]] $comment_html_p]</select>
</blockquote>
<br>
<center>
<input type=submit name=submit value=\"Proceed\">
</center>
</form>
[ad_footer]"



