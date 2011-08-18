# $Id: comment-add-2.tcl,v 3.1 2000/03/11 09:03:02 aileen Exp $
# File:     /calendar/comment-add-2.tcl
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

set_the_usual_form_variables 0
# calendar_id, content, comment_id, html_p
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)

ad_scope_error_check

set db [ns_db gethandle]
ad_scope_authorize $db $scope all group_member registered

# check for bad input
if { ![info exists content] || [empty_string_p $content] } {
    ad_scope_return_complaint 1 "<li>the comment field was empty" $db
    return
}

set title [database_to_tcl_string $db "select title from calendar where calendar_id=$calendar_id"]

ReturnHeaders

ns_write "
[ad_scope_header "Confirm comment on <i>$title</i>" $db ]
[ad_scope_page_title "Confirm comment" $db]
[ad_scope_context_bar_ws_or_index [list "index.tcl?[export_url_scope_vars]" [ad_parameter SystemName calendar "Calendar"]] [list "item.tcl?[export_url_scope_vars calendar_id]" "One Item"] "Confirm Comment"]


<hr>
[ad_scope_navbar]

The following is your comment as it would appear on the page <i>$title</i>.
If it looks incorrect, please use the back button on your browser to return and
correct it.  Otherwise, press \"Continue\".
<p>
<blockquote>"

if { [info exists html_p] && $html_p == "t" } {
    ns_write "$content
</blockquote>
Note: if the story has lost all of its paragraph breaks then you
probably should have selected \"Plain Text\" rather than HTML.  Use
your browser's Back button to return to the submission form.
"
} else {
    ns_write "[util_convert_plaintext_to_html $content]
</blockquote>

Note: if the story has a bunch of visible HTML tags then you probably
should have selected \"HTML\" rather than \"Plain Text\".  Use your
browser's Back button to return to the submission form.  " 
}


ns_write "<form action=comment-add-3.tcl method=post>
<center>
<input type=submit name=submit value=\"Confirm\">
</center>
[export_form_scope_vars content calendar_id comment_id html_p]
</form>
[ad_scope_footer]
"
