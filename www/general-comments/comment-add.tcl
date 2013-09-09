# /general-comments/comment-add.tcl

ad_page_contract {
    @author philg@mit.edu
    @author tarik@mit.edu
    @creation-date 01/21/2000
    @cvs-id comment-add.tcl,v 3.4.2.5 2001/01/10 20:07:16 khy Exp
} {
    on_which_table
    on_what_id
    item
    module
    return_url   
}

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

# check for the user cookie
set user_id [ad_get_user_id]
ad_maybe_redirect_for_registration


set comment_id [db_string unused "select general_comment_id_sequence.nextval from dual"]

db_release_unused_handles

if {[ad_parameter UseTitlesP "general-comments" 0]} {
    set title_text "Title:<br>
<input type=text name=one_line maxlenth=200>
<p>
Comment:<br>
"     
} else {
    set title_text ""
}

doc_return  200 text/html "[ad_header "Add a comment to $item"]

<h2>Add a comment to $item</h2>

[ad_context_bar_ws [list $return_url $item] "Add a comment"]

<hr>

Comment on $item:

<blockquote>
<form action=comment-add-2 method=post>
[export_form_vars on_which_table on_what_id item return_url module scope group_id]
[export_form_vars -sign comment_id]
$title_text
<textarea name=content cols=80 rows=20 wrap=soft></textarea><br>
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
