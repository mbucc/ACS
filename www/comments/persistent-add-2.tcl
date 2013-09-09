ad_page_contract {
    @author teadams@mit.edu
    @creation-date mid-1998
    @param page_id
    @param message
    @param comment_type
    @param html_p
    @cvs-id persistent-add-2.tcl,v 3.2.2.6 2000/09/22 01:37:17 kevin Exp
} {
    {page_id:naturalnum,notnull}
    message:html
    comment_type
    html_p
}

# check for bad input
if { ![info exists message] || [empty_string_p $message] } {
    ad_return_complaint 1 "<li>please type a comment!"
    return
}

if { $html_p == "t" && ![empty_string_p [ad_check_for_naughty_html $message]] } {
    ad_return_complaint 1 "<li>[ad_check_for_naughty_html $message]\n"
    return
}



set selection [db_0or1row comments_persistent_add_2_page_data_get "
select nvl(page_title,url_stub) as page_title, url_stub
from static_pages
where page_id = :page_id"]

if {$selection == 0} {
    ad_return_complaint "Invalid page id" "Page id could not found"
    db_release_unused_handles
    return
}

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

set comment_id [db_string comments_persistent_add_comment_id_get "select
comment_id_sequence.nextval from dual"]

append whole_page "<form action=comment-add method=post>
[export_form_vars message comment_type page_id comment_id html_p]
<center>
<input type=submit name=submit value=\"Proceed\">
</center>
</form>

[ad_footer]
"

doc_return  200 text/html $whole_page











