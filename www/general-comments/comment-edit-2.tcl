ad_page_contract {
    @author philg@mit.edu
    @author tarik@mit.edu
    @creation-date 01/21/2000
    @cvs-id comment-edit-2.tcl,v 3.3.2.6 2000/09/22 01:38:01 kevin Exp
} {
    comment_id:integer
    item
    module     
    html_p
    {content:html ""}
    {one_line ""}
    {return_url ""}
}

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}



# check for bad input
if  {![info exists content] || [empty_string_p $content] } { 
    ad_return_complaint 1 "<li>the comment field was empty"
    return
}

if { $html_p == "t" && ![empty_string_p [ad_check_for_naughty_html $content]] } {
    ad_return_complaint 1 "<li>[ad_check_for_naughty_html $content]\n"
    return
}


set user_id [ad_get_user_id]

db_1row comment_get "select  general_comments.user_id as comment_user_id,
                             on_what_id, on_which_table
                     from  general_comments
                     where comment_id = :comment_id" -bind [ad_tcl_vars_to_ns_set comment_id]

# check to see if ther user was the orginal poster
if {$user_id != $comment_user_id &&  ![ad_permission_p $module $submodule]} {
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

append page_content "
[ad_header "Confirm comment on $item" ]

<h2>Confirm comment on $item</h2>
"

if { ![empty_string_p $return_url] } {
    append page_content "
    [ad_context_bar_ws [list "$return_url" "$item"]  "Confirm comment"]
    "
} else {
    append page_content "
    [ad_context_bar_ws "Confirm comment"]
    "
}

append page_content "
<hr>

Here is how your comment would appear:

$approval_text

<center>
<form action=comment-edit-3 method=post>
[export_entire_form]
<input type=submit name=submit value=\"Confirm\">
</form>
</center>
[ad_footer]
"

doc_return  200 text/html $page_content
