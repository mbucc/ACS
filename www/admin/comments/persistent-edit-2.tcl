# /www/admin/comments/persistent-edit-2.tcl

ad_page_contract {
    
    @param comment_id
    @param page_id
    @param submit
    @param message
    @param comment_type
    @param html_p

    @cvs-id persistent-edit-2.tcl,v 3.2.2.4 2000/09/22 01:34:32 kevin Exp
} {
    comment_id:integer
    page_id:integer
    submit
    message:optional
    comment_type:optional
    html_p:optional
    
}

db_1row comment_display "select static_pages.url_stub, nvl(page_title, url_stub) as page_title 
from static_pages
where page_id = :page_id"

if {  [regexp -nocase "delete" $submit] } {
    #user wants to delete the comment

    db_1row message_display "select message, html_p from comments where comment_id = :comment_id"

    set html  "[ad_admin_header "Verify comment deletion on <i>$page_title</i>" ]

<h2>Verify comment deletion</h2>

on <a href=\"$url_stub\">$page_title</a>
<hr>

You have asked to delete the following comment  on the page <i>$page_title</i>.
<p>

<blockquote>
[util_maybe_convert_to_html $message $html_p]
</blockquote>

<form action=comment-delete method=post>
[export_form_vars comment_id page_id]
<center>
<input type=submit name=submit value=\"Delete Comment\">
</center>
</form>"

} else {

    # user wants to edit the comment
    # check for bad input
    if { (![info exists message] || [empty_string_p $message]) && [regexp -nocase "delete" $submit] } {
	ad_return_complaint 1 "<li>please type a comment!"
	return
    }

    if { [info exists html_p] && $html_p == "t" } {
	set pretty_message $message
    } else {
	set pretty_message [util_convert_plaintext_to_html $message]
    }

    append html "[ad_admin_header "Verify comment on <i>$page_title</i>" ]

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

append html "[ad_admin_footer]"



doc_return  200 text/html $html