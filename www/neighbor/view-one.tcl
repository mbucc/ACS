# $Id: view-one.tcl,v 3.0 2000/02/06 03:50:02 ron Exp $
#
# /neighbor/view-one.tcl
#
# by philg@mit.edu in the dark ages of 1998 (ported from 1995-era code)
# 

set viewing_user_id [ad_get_user_id]

set_form_variables

# neighbor_to_neighbor_id is set now

set db [neighbor_db_gethandle]

set selection [ns_db 0or1row $db "select about, title, body, html_p, posted, users.user_id, users.first_names || ' ' || users.last_name as poster_name, n.category_id, pc.primary_category
from neighbor_to_neighbor n, users, n_to_n_primary_categories pc
where neighbor_to_neighbor_id = $neighbor_to_neighbor_id
and users.user_id = n.poster_user_id
and n.category_id = pc.category_id"]

if { $selection == "" } {
    # user is looking at an old posting
    ad_return_error "Bad story id" "Couldn't find posting number $neighbor_to_neighbor_id.

<P>

Probably you've bookmarked an old story
that has been deleted by the moderator."
    return
}

# found the row

set_variables_after_query

if [empty_string_p $title] {
    set headline $about
} else {
    set headline "$about : $title"
}


ReturnHeaders

ns_write "[neighbor_header $headline]

<h2>$headline</h2>

posted in [neighbor_home_link $category_id $primary_category]

<hr>

<blockquote>
[util_maybe_convert_to_html $body $html_p]
<br>
<br>
-- <a href=\"/shared/community-member.tcl?user_id=$user_id\">$poster_name</a>, [util_AnsiDatetoPrettyDate $posted]
</blockquote>


"

if [ad_parameter SolicitCommentsP neighbor 1] {
    # see if there are any comments on this story
    set selection [ns_db select $db "select comment_id, content, comment_date, first_names || ' ' || last_name as commenter_name, users.user_id as comment_user_id, html_p as comment_html_p
from general_comments, users
where on_what_id= $neighbor_to_neighbor_id
and on_which_table = 'neighbor_to_neighbor'
and general_comments.approved_p = 't'
and general_comments.user_id = users.user_id"]

    set first_iteration_p 1
    set comment_html ""
    while {[ns_db getrow $db $selection]} {
	set_variables_after_query
	if $first_iteration_p {
	    append comment_html "<h4>Comments</h4>\n"
	    set first_iteration_p 0
	}
	append comment_html "<blockquote>\n[util_maybe_convert_to_html $content $comment_html_p]\n"
	# if the user posted the comment, they are allowed to edit it
	if {$viewing_user_id == $comment_user_id} {
	    append comment_html "<br><br>-- you <A HREF=\"comment-edit.tcl?comment_id=$comment_id\">(edit your comment)</a>"
	} else {
	    append comment_html "<br><br>-- <a href=\"/shared/community-member.tcl?user_id=$comment_user_id\">$commenter_name</a>"
	}
	append comment_html ", [util_AnsiDatetoPrettyDate $comment_date]"
	append comment_html "</blockquote>\n"
    }
    append comment_html "
    <center>
    <A HREF=\"comment-add.tcl?[export_url_vars neighbor_to_neighbor_id]\">Add a comment</a>
    </center>
    "
    ns_write $comment_html 
} else {
    # we're not soliciting comments
}


ns_write "
</body>
</html>
"
