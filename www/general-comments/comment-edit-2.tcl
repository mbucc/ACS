# $Id: comment-edit-2.tcl,v 3.0 2000/02/06 03:43:57 ron Exp $
# File:     /general-comments/comment-edit-2.tcl
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
# comment_id, on_what_id, on_which_table, item, module, return_url
# check for bad input

if  {![info exists content] || [empty_string_p $content] } { 
    ad_return_complaint 1 "<li>the comment field was empty"
    return
}

if { $html_p == "t" && ![empty_string_p [ad_check_for_naughty_html $content]] } {
    ad_return_complaint 1 "<li>[ad_check_for_naughty_html $content]\n"
    return
}

if {![info exists one_line]} {
    set one_line ""
}


set db [ns_db gethandle]
set user_id [ad_get_user_id]

set selection [ns_db 1row $db "select  general_comments.user_id as comment_user_id
from  general_comments
where comment_id = $comment_id"]

set_variables_after_query

# check to see if ther user was the orginal poster
if {$user_id != $comment_user_id &&  ![ad_permission_p $db $module $submodule]} {
    ad_return_complaint 1 "<li>You can not edit this entry because you did not post it"
    return
}


if { [info exists html_p] && $html_p == "t" } {
    set approval_text "<blockquote>
<h4>$one_line</h4>
$content
</blockquote>
[ad_style_bodynote "Note: if the text above has lost all of its paragraph breaks then you
probably should have selected \"Plain Text\" rather than HTML.  Use
your browser's Back button to return to the submission form."]
"
} else {
    set approval_text "<blockquote>
<h4>$one_line</h4>
[util_convert_plaintext_to_html $content]
</blockquote>

[ad_style_bodynote "Note: if the text above has a bunch of visible HTML tags then you probably
should have selected \"HTML\" rather than \"Plain Text\".  Use your
browser's Back button to return to the submission form."]"
}

ns_return 200 text/html "[ad_header "Confirm comment on $item" ]

<h2>Confirm comment on $item</h2>

[ad_context_bar_ws [list "$return_url" "$item"]  "Confirm comment"]

<hr>

Here is how your comment would appear:


$approval_text

<center>
<form action=comment-edit-3.tcl method=post>
[export_entire_form]
<input type=submit name=submit value=\"Confirm\">
</form>
</center>
[ad_footer]
"

