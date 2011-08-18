# $Id: view-one.tcl,v 3.0 2000/02/06 03:26:22 ron Exp $
#
# /admin/neighbor/view-one.tcl
#
# by philg@mit.edu sometime in 1998, ported from horrible
# old legacy Illustra-backed code from 1995
#

set_form_variables

# neighbor_to_neighbor_id is set now

set db [neighbor_db_gethandle]

set selection [ns_db 0or1row $db "select about, title, body, html_p, posted, n.approved_p, users.user_id, users.first_names || ' ' || users.last_name as poster_name, n.category_id, pc.primary_category, nns.subcategory_1
from neighbor_to_neighbor n, users, n_to_n_subcategories nns, n_to_n_primary_categories pc
where neighbor_to_neighbor_id = $neighbor_to_neighbor_id
and n.subcategory_id = nns.subcategory_id
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

posted in $subcategory_1 <a href=\"category.tcl?[export_url_vars category_id]\">$primary_category</a>

<hr>"

ns_write "
<ul>
<li>Status:  
"

if {$approved_p == "t" } {
    ns_write "Approved (<a href=\"toggle-approved-p.tcl?[export_url_vars  neighbor_to_neighbor_id]\">Revoke</a>)"
} else {
    ns_write "<font color=red>Awaiting approval</font> (<a href=\"toggle-approved-p.tcl?[export_url_vars  neighbor_to_neighbor_id]\">Approve</a>)"
}


ns_write "
</ul>
<blockquote>

[util_maybe_convert_to_html $body $html_p]
<br>
<br>
-- <a href=\"/admin/users/one.tcl?user_id=$user_id\">$poster_name</a>, [util_AnsiDatetoPrettyDate $posted]
</blockquote>

"

if [ad_parameter SolicitCommentsP neighbor 1] {
    # see if there are any comments on this story
    set selection [ns_db select $db "select comment_id, content, comment_date, general_comments.approved_p as comment_approved_p, first_names || ' ' || last_name as commenter_name, users.user_id as comment_user_id, html_p as comment_html_p
from general_comments, users
where on_what_id= $neighbor_to_neighbor_id
and on_which_table = 'neighbor_to_neighbor'
and general_comments.user_id = users.user_id"]

    set first_iteration_p 1
    while {[ns_db getrow $db $selection]} {
	set_variables_after_query
	if $first_iteration_p {
	    ns_write "<h4>Comments</h4>\n"
	    set first_iteration_p 0
	}
	ns_write "<blockquote>\n[util_maybe_convert_to_html $content $comment_html_p]\n"
	ns_write "<br><br>-- <a href=\"/shared/community-member.tcl?user_id=$comment_user_id\">$commenter_name</a> (<a href=\"../general-comments/edit.tcl?comment_id=$comment_id\">edit</a>)\n"
	if {$comment_approved_p == "t" } {
	    ns_write "&nbsp; &nbsp; Approved (<a href=\"../general-comments/toggle-approved-p.tcl?[export_url_vars comment_id]\">Revoke</a>)"
	} else {
	    ns_write "&nbsp; &nbsp; <font color=red>Awaiting approval</font> (<a href=\"../general-comments/toggle-approved-p.tcl?[export_url_vars comment_id]\">Approve</a>)"
	}
	ns_write "</blockquote>"
    }
    ns_write "
    <center>
    <A HREF=\"/neighbor/comment-add.tcl?[export_url_vars neighbor_to_neighbor_id]\">Add a comment</a>
    </center>
    "
}

ns_write [ad_admin_footer]
