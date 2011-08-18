# $Id: persistent-edit-2.tcl,v 3.0 2000/02/06 03:37:21 ron Exp $
#
# /comments/persistent-edit-2.tcl
#
# by teadams@mit.edu in mid-1998
#
# this is a verification page; the real work is 
# done by comment-edit.tcl (for editing) or
# comment-delete.tcl (deletion)
#
# updated January 22, 2000 by philg@mit.edu
# to look for naughty HTML
# 

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set_form_variables
# page_id, message, comment_type, comment_id, submit, html_p

# check for bad input
if { (![info exists message] || [empty_string_p $message]) && [regexp -nocase "delete" $submit] } {
    ad_return_complaint 1 "<li>please type a comment!"
    return
}

if { [info exists html_p] && $html_p == "t" && ![empty_string_p [ad_check_for_naughty_html $message]] } {
    ad_return_complaint 1 "<li>[ad_check_for_naughty_html $message]\n"
    return
}

set db [ns_db gethandle]
set selection [ns_db 1row $db "select static_pages.url_stub, nvl(page_title, url_stub) as page_title 
from static_pages
where page_id = $page_id"]
set_variables_after_query
ns_db releasehandle $db

ReturnHeaders

if { [info exists html_p] && $html_p == "t" } {
    set pretty_message $message
} else {
    set pretty_message [util_convert_plaintext_to_html $message]
}

if {  [regexp -nocase "delete" $submit] } {
    #user wants to delete the comment
    ns_write "[ad_header "Verify comment deletion on <i>$page_title</i>" ]

<h2>Verify comment deletion</h2>

on <a href=\"$url_stub\">$page_title</a>
<hr>

You have asked to delete the following comment  on the page <i>$page_title</i>.
<p>

<blockquote>
$pretty_message
</blockquote>

<form action=comment-delete.tcl method=post>
[export_form_vars comment_id page_id]
<center>
<input type=submit name=submit value=\"Delete Comment\">
<input type=submit name=submit value=\"Cancel\">
</center>
</form>"

} else {
    # user wants to edit the comment
    ns_write "[ad_header "Verify comment on <i>$page_title</i>" ]

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
	ns_write "<p>
Note: if the comment has lost all of its paragraph breaks then you
probably should have selected \"Plain Text\" rather than HTML.  Use
your browser's Back button to return to the submission form.
"
    } else {
	ns_write "<p>
Note: if the comment has a bunch of visible HTML tags then you probably
should have selected \"HTML\" rather than \"Plain Text\".  Use your
browser's Back button to return to the submission form. "
    }

    ns_write "
<form action=comment-edit.tcl method=post>
[export_form_vars message html_p page_id comment_id]
<input type=hidden name=comment_type value=alternative_perspective>
<center>
<input type=submit name=submit value=\"Proceed\">
</center>
</form>"
}

ns_write "[ad_footer]"






