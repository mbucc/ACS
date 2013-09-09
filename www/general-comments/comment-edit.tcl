ad_page_contract {
    @author philg@mit.edu
    @author tarik@mit.edu
    @creation-date 01/21/2000
    @cvs-id comment-edit.tcl,v 3.4.2.5 2000/09/22 01:38:01 kevin Exp
} {
    comment_id
    item
    {module ""}
    {return_url ""}    
}

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

# check for the user cookie
set user_id [ad_get_user_id]
ad_maybe_redirect_for_registration


db_1row comment_get "select comment_id, content, general_comments.html_p as comment_html_p, general_comments.user_id as comment_user_id, one_line
from general_comments
where comment_id = :comment_id" -bind [ad_tcl_vars_to_ns_set comment_id]

# check to see if ther user was the orginal poster
if {$user_id != $comment_user_id && ![ad_permission_p $module $submodule]} {
    ad_return_complaint 1 "<li>You can not edit this entry because you did not post it"
    return
}

if {[ad_parameter UseTitlesP "general-comments" 0]} {
    set title_text "Title:<br>
<input type=text name=one_line maxlength=200 [export_form_value one_line]>
<p>
Comment:<br>
"     
} else {
    set title_text ""
}

append page_content "
[ad_header "Edit comment on $item" ]

<h2>Edit comment on $item</h2>
"

if { [info exists return_url] } {
    append page_content "
    [ad_context_bar_ws  [list "$return_url" $item]  "Edit comment"]
    "
} else {
    append page_content "
    [ad_context_bar_ws  "Edit comment"]
    "
}

append page_content "
<hr>

<P>
Edit your comment.<br>

<form action=comment-edit-2 method=post>
[export_form_vars comment_id module submodule return_url item]

<blockquote>

$title_text

<textarea name=content cols=80 rows=20 wrap=soft>[ns_quotehtml $content]</textarea><br>
Text above is
<select name=html_p>[html_select_value_options [list [list "f" "Plain Text" ] [list  "t" "HTML" ]] $comment_html_p]</select>
</blockquote>
<br>
<center>
<input type=submit name=submit value=\"Proceed\">
</center>
</form>
[ad_footer]"


doc_return  200 text/html $page_content

