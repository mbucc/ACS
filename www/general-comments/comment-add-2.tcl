ad_page_contract {
    @author philg@mit.edu
    @author tarik@mit.edu
    @creation-date 01/21/2000
    @cvs-id comment-add-2.tcl,v 3.2.2.5 2001/01/10 20:07:41 khy Exp
} {
    {scope ""}
    {user_id ""}
    {group_id ""}
    {on_which_group ""}
    {on_what_id ""}
    on_which_table
    on_what_id
    content:html
    comment_id:naturalnum,notnull,verify
    html_p
    return_url
    item
    module
    {one_line ""}
}


if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

#####
if {![info exists content] } {
    ad_return_complaint 1 "content doesn't exist!?"
    return
}

if {[empty_string_p $content]} {
    ad_return_complaint 1 "content is empty '$content'"
    return
}
###########


# check for bad input
if { ![info exists content] || [empty_string_p $content] } {
    ad_return_complaint 1 "<li>please type something"
    return
}

# this is already done by ad_page_contract 
#if { $html_p == "t" && ![empty_string_p [ad_check_for_naughty_html $content]] } {
#    ad_return_complaint 1 "<li>[ad_check_for_naughty_html $content]\n"
#    return
#}

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

# Get the default approval policy for the site
set approval_policy [ad_parameter DefaultCommentApprovalPolicy]

# If there is a different approval policy for the module, override
# the site approval policy
set approval_policy [ad_parameter CommentApprovalPolicy $module $approval_policy]

# If the comment will require approval tell the user that it will not appear immediately.
if { ![ad_parameter AcceptAttachmentsP "general-comments" 0] && [string compare $approval_policy "open"] != 0 } {
    append approval_text "<p>Your comment will be visible after it is approved by the administrator.\n"
}

doc_return  200 text/html "[ad_header "Confirm comment on $item"]

<h2>Confirm comment on $item</h2>

[ad_context_bar_ws [list $return_url $item] "Confirm comment"]

<hr>

Here is how your comment would appear:

$approval_text

<center>
<form action=comment-add-3 method=post>
[export_entire_form]
<input type=submit name=submit value=\"Confirm\">
</form>
</center>

[ad_footer]
"
