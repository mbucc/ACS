# $Id: comment-add-2.tcl,v 3.0.4.1 2000/04/28 15:11:12 carsten Exp $
if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

#check for the user cookie

set user_id [ad_get_user_id]

if { $user_id == 0 } {
    ad_returnredirect /register/index.tcl    
    return
}

set_the_usual_form_variables

# neighbor_to_neighbor_id, content, comment_id, html_p

# check for bad input
if { ![info exists content] || [empty_string_p $content] } {
    ad_return_complaint 1 "<li>the comment field was empty"
    return
}

set db [ns_db gethandle]
    
set selection [ns_db 1row $db "select about, title from neighbor_to_neighbor where neighbor_to_neighbor_id = $neighbor_to_neighbor_id"]
set_variables_after_query

ReturnHeaders

ns_write "[ad_header "Confirm comment on <i>$about : $title</i>" ]

<h2>Confirm comment</h2>

on <A HREF=\"view-one.tcl?[export_url_vars neighbor_to_neighbor_id]\">$about : $title</a>

<hr>

The following is your comment as it would appear on the page <i>$title</i>.
If it looks incorrect, please use the back button on your browser to return and
correct it.  Otherwise, press \"Continue\".
<p>
<blockquote>"

if { [info exists html_p] && $html_p == "t" } {
    ns_write "$content
</blockquote>
Note: if the story has lost all of its paragraph breaks then you
probably should have selected \"Plain Text\" rather than HTML.  Use
your browser's Back button to return to the submission form.
"
} else {
    ns_write "[util_convert_plaintext_to_html $content]
</blockquote>

Note: if the story has a bunch of visible HTML tags then you probably
should have selected \"HTML\" rather than \"Plain Text\".  Use your
browser's Back button to return to the submission form.  " 
}


ns_write "<form action=comment-add-3.tcl method=post>
<center>
<input type=submit name=submit value=\"Confirm\">
</center>
[export_entire_form]
</form>
[ad_footer]
"
