# admin/neighbor/view-one.tcl

ad_page_contract {
    @param neighbor_to_neighbor_id

    @author Phil Greenspun philg@arsdigita.com
    @creation-date 2000-02-17
    @cvs-id view-one.tcl,v 3.2.2.3 2000/09/22 01:35:42 kevin Exp

    displays information about one neighbor section
} {
    neighbor_to_neighbor_id:integer
}

##########
## Old Comments
##########
# view-one.tcl,v 3.2.2.3 2000/09/22 01:35:42 kevin Exp
#
# /admin/neighbor/view-one.tcl
#
# by philg@mit.edu sometime in 1998, ported from horrible
# old legacy Illustra-backed code from 1995
#
#


set sql_query "
select about, title, body, html_p, posted, n.approved_p, 
users.user_id, 
users.first_names || ' ' || users.last_name as poster_name, 
n.category_id, 
pc.primary_category, nns.subcategory_1
from neighbor_to_neighbor n, users, 
n_to_n_subcategories nns, n_to_n_primary_categories pc
where neighbor_to_neighbor_id = :neighbor_to_neighbor_id
and n.subcategory_id = nns.subcategory_id
and users.user_id = n.poster_user_id
and n.category_id = pc.category_id"


if {![db_0or1row neighbor_category_select $sql_query]} {
    ad_return_error "Bad story id" "Couldn't find posting number $neighbor_to_neighbor_id.
    <P>
    Probably you've bookmarked an old story
    that has been deleted by the moderator."
    return
}

# found the row

if [empty_string_p $title] {
    set headline $about
} else {
    set headline "$about : $title"
}

set doc_body "[neighbor_header $headline]
    
<h2>$headline</h2>

posted in $subcategory_1 <a href=\"category?[export_url_vars category_id]\">$primary_category</a>

<hr>
<ul>
<li>Status:  
"

if {$approved_p == "t" } {
    append doc_body "Approved (<a href=\"toggle-approved-p?[export_url_vars  neighbor_to_neighbor_id]\">Revoke</a>)"
} else {
    append doc_body "<font color=red>Awaiting approval</font> (<a href=\"toggle-approved-p?[export_url_vars  neighbor_to_neighbor_id]\">Approve</a>)"
}

append doc_body "
</ul>
<blockquote>

[util_maybe_convert_to_html $body $html_p]
<br>
<br>
-- <a href=\"/admin/users/one?user_id=$user_id\">$poster_name</a>, [util_AnsiDatetoPrettyDate $posted]
</blockquote>

"

if [ad_parameter SolicitCommentsP neighbor 1] {
    # see if there are any comments on this story
    set sql_query "
    select comment_id, content, comment_date, 
    general_comments.approved_p as comment_approved_p, 
	first_names || ' ' || last_name as commenter_name, 
    users.user_id as comment_user_id, 
    html_p as comment_html_p
    from general_comments, users
    where on_what_id= :neighbor_to_neighbor_id
    and on_which_table = 'neighbor_to_neighbor'
	and general_comments.user_id = users.user_id"
    
    set first_iteration_p 1
    db_foreach neighbor_comment $sql_query {
	if $first_iteration_p {
	    append doc_body "<h4>Comments</h4>\n"
	    set first_iteration_p 0
	}
	append doc_body "<blockquote>\n[util_maybe_convert_to_html $content $comment_html_p]\n"
	append doc_body "<br><br>-- <a href=\"/shared/community-member?user_id=$comment_user_id\">$commenter_name</a> (<a href=\"../general-comments/edit?comment_id=$comment_id\">edit</a>)\n"
	if {$comment_approved_p == "t" } {
	    append doc_body "&nbsp; &nbsp; Approved (<a href=\"../general-comments/toggle-approved-p?[export_url_vars comment_id]\">Revoke</a>)"
	} else {
	    append doc_body "&nbsp; &nbsp; <font color=red>Awaiting approval</font> (<a href=\"../general-comments/toggle-approved-p?[export_url_vars comment_id]\">Approve</a>)"
	}
	append doc_body "</blockquote>"
    }
    append doc_body "
    <center>
    <A HREF=\"/neighbor/comment-add?[export_url_vars neighbor_to_neighbor_id]\">Add a comment</a>
    </center>
    "
}

append doc_body [ad_admin_footer]


doc_return  200 text/html $doc_body
