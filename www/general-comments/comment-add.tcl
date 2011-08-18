# $Id: comment-add.tcl,v 3.1 2000/02/20 10:57:05 ron Exp $
# File:     /general-comments/comment-add.tcl
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
# on_which_table, on_what_id, item, module, return_url

# check for the user cookie
set user_id [ad_get_user_id]
ad_maybe_redirect_for_registration

set db [ns_db gethandle]
set comment_id [database_to_tcl_string $db "select general_comment_id_sequence.nextval from dual"]

ns_db releasehandle $db

if {[ad_parameter UseTitlesP "general-comments" 0]} {
    set title_text "Title:<br>
<input type=text name=one_line maxlenth=200>
<p>
Comment:<br>
"     
} else {
    set title_text ""
}


ns_return 200 text/html "[ad_header "Add a comment to $item"]

<h2>Add a comment to $item</h2>

[ad_context_bar_ws [list $return_url $item] "Add a comment"]

<hr>

Comment on $item:

<blockquote>
<form action=comment-add-2.tcl method=post>
[export_form_vars on_which_table on_what_id comment_id item return_url module scope group_id]
$title_text
<textarea name=content cols=50 rows=5 wrap=soft></textarea><br>
Text above is
<select name=html_p>
[html_select_value_options [list [list "f" "Plain Text" ] [list  "t" "HTML" ]]]
</select>
</blockquote>
<br>
<center>
<input type=submit name=submit value=\"Proceed\">
</center>
</form>
[ad_footer]
"
