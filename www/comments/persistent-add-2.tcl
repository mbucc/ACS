# $Id: persistent-add-2.tcl,v 3.0 2000/02/06 03:37:19 ron Exp $
#
# /comments/persistent-add-2.tcl
#
# written in mid-1998 by teadams@mit.edu
#
# enhanced January 21, 2000 by philg@mit.edu 
# to check for naughty HTML 
#

set_form_variables

# page_id, message, comment_type,  html_p

# check for bad input
if { ![info exists message] || [empty_string_p $message] } {
    ad_return_complaint 1 "<li>please type a comment!"
    return
}

if { $html_p == "t" && ![empty_string_p [ad_check_for_naughty_html $message]] } {
    ad_return_complaint 1 "<li>[ad_check_for_naughty_html $message]\n"
    return
}

set db [ns_db gethandle]

set selection [ns_db 1row $db "select nvl(page_title,url_stub) as page_title, url_stub
from static_pages
where page_id = $page_id"]
set_variables_after_query

set whole_page ""

append whole_page "[ad_header "Confirm comment on <i>$page_title</i>" ]

<h2>Confirm comment</h2>

on <a href=\"$url_stub\">$page_title</a>
<hr>

The following is your comment as it would appear on the page <i>$page_title</i>.
If it looks incorrect, please use the back button on your browser to return and
correct it.  Otherwise, press \"Proceed\".
<p>
<blockquote>"

if { [info exists html_p] && $html_p == "t" } {
    append whole_page "$message
</blockquote>
<p>
Note: if the comment has lost all of its paragraph breaks then you
probably should have selected \"Plain Text\" rather than HTML.  Use
your browser's Back button to return to the submission form.
"
} else {
    append whole_page "[util_convert_plaintext_to_html $message]
</blockquote> 
<p>
Note: if the comment has a bunch of visible HTML tags then you probably
should have selected \"HTML\" rather than \"Plain Text\".  Use your
browser's Back button to return to the submission form. "
}

set comment_id [database_to_tcl_string $db "select
comment_id_sequence.nextval from dual"]

append whole_page "<form action=comment-add.tcl method=post>
[export_form_vars message comment_type page_id comment_id html_p]
<center>
<input type=submit name=submit value=\"Proceed\">
</center>
</form>

[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $whole_page
