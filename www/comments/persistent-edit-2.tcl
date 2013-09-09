# www/comments/persistent-edit-2.tcl

ad_page_contract {
    this is a verification page; the real work is 
    done by comment-edit.tcl (for editing) or
    comment-delete.tcl (deletion)

    @author teadams@mit.edu
    @creation-date mid-1998
    @param page_id
    @param message
    @param comment_type
    @param comment_id
    @param submit
    @param html_p
    @cvs-id persistent-edit-2.tcl,v 3.1.6.5 2000/09/22 01:37:17 kevin Exp
} {
    {page_id:naturalnum,notnull}
    message:html
    comment_type
    {comment_id:naturalnum,notnull}
    submit
    html_p    
}

# updated January 22, 2000 by philg@mit.edu
# to look for naughty HTML


if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}


# check for bad input
if { (![info exists message] || [empty_string_p $message]) && [regexp -nocase "delete" $submit] } {
    ad_return_complaint 1 "<li>please type a comment!"
    return
}

if { [info exists html_p] && $html_p == "t" && ![empty_string_p [ad_check_for_naughty_html $message]] } {
    ad_return_complaint 1 "<li>[ad_check_for_naughty_html $message]\n"
    return
}


set selection [db_0or1row comments_persistent_edit_page_data_get "
select static_pages.url_stub, nvl(page_title, url_stub) as page_title 
from static_pages
where page_id = :page_id"]

if {$selection == 0} {
    ad_return_complaint "Invalid page id" "Page id could not be found"
    db_release_unused_handles
    return
}
    
if { [info exists html_p] && $html_p == "t" } {
    set pretty_message $message
} else {
    set pretty_message [util_convert_plaintext_to_html $message]
}

set html ""

if {  [regexp -nocase "delete" $submit] } {
    #user wants to delete the comment
    append html "[ad_header "Verify comment deletion on <i>$page_title</i>" ]

<h2>Verify comment deletion</h2>

on <a href=\"$url_stub\">$page_title</a>
<hr>

You have asked to delete the following comment  on the page <i>$page_title</i>.
<p>

<blockquote>
$pretty_message
</blockquote>

<form action=comment-delete method=post>
[export_form_vars comment_id page_id]
<center>
<input type=submit name=submit value=\"Delete Comment\">
<input type=submit name=submit value=\"Cancel\">
</center>
</form>"

} else {
    # user wants to edit the comment
    append html "[ad_header "Verify comment on <i>$page_title</i>" ]

<h2>Verify comment</h2>

on <a href=\"$url_stub\">$page_title</a>
<hr>

The following is your comment as it would appear on the page <i>$page_title</i>.
If it looks incorrect, please use the back button on your browser to return and
correct it.  Otherwise, press \"Proceed\".
<p>

<blockquote>
$pretty_message
</blockquote>"


    if { [info exists html_p] && $html_p == "t" } {
	append html "<p>
Note: if the comment has lost all of its paragraph breaks then you
probably should have selected \"Plain Text\" rather than HTML.  Use
your browser's Back button to return to the submission form.
"
    } else {
	append html "<p>
Note: if the comment has a bunch of visible HTML tags then you probably
should have selected \"HTML\" rather than \"Plain Text\".  Use your
browser's Back button to return to the submission form. "
    }

    append html "
<form action=comment-edit method=post>
[export_form_vars message html_p page_id comment_id]
<input type=hidden name=comment_type value=alternative_perspective>
<center>
<input type=submit name=submit value=\"Proceed\">
</center>
</form>"
}

append html "[ad_footer]"

doc_return 200 text/html $html





