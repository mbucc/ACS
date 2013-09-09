# /www/neighbor/view-one.tcl
ad_page_contract {
    Displays one neighbor-to-neighbor story.

    @author Philip Greenspun (philg@mit.edu)
    @creation-date 1 January 1998
    @cvs-id view-one.tcl,v 3.1.6.3 2000/09/22 01:38:56 kevin Exp
} {
    neighbor_to_neighbor_id:integer,notnull
}

set viewing_user_id [ad_get_user_id]

set sql_query "
  select about, title, body, html_p, posted, users.user_id, 
         users.first_names || ' ' || users.last_name as poster_name,
         n.category_id, pc.primary_category
    from neighbor_to_neighbor n, users, n_to_n_primary_categories pc
   where neighbor_to_neighbor_id = :neighbor_to_neighbor_id
     and users.user_id = n.poster_user_id
     and n.category_id = pc.category_id"

if {![db_0or1row select_story $sql_query]} {
    # user is looking at an old posting
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


set page_content "[neighbor_header $headline]

<h2>$headline</h2>

posted in [neighbor_home_link $category_id $primary_category]

<hr>

<blockquote>
[util_maybe_convert_to_html $body $html_p]
<br>
<br>
-- <a href=\"/shared/community-member?user_id=$user_id\">$poster_name</a>, [util_AnsiDatetoPrettyDate $posted]
</blockquote>


"

if [ad_parameter SolicitCommentsP neighbor 1] {
    # see if there are any comments on this story
    set sql_query "
      select comment_id, content, comment_date,
             first_names || ' ' || last_name as commenter_name,
             users.user_id as comment_user_id, html_p as comment_html_p
        from general_comments, users
       where on_what_id= $neighbor_to_neighbor_id
         and on_which_table = 'neighbor_to_neighbor'
         and general_comments.approved_p = 't'
         and general_comments.user_id = users.user_id"

    set first_iteration_p 1
    set comment_html ""
    db_foreach select_comments $sql_query {
	if $first_iteration_p {
	    append comment_html "<h4>Comments</h4>\n"
	    set first_iteration_p 0
	}
	append comment_html "<blockquote>\n[util_maybe_convert_to_html $content $comment_html_p]\n"
	# if the user posted the comment, they are allowed to edit it
	if {$viewing_user_id == $comment_user_id} {
	    append comment_html "<br><br>-- you <A HREF=\"comment-edit?comment_id=$comment_id\">(edit your comment)</a>"
	} else {
	    append comment_html "<br><br>-- <a href=\"/shared/community-member?user_id=$comment_user_id\">$commenter_name</a>"
	}
	append comment_html ", [util_AnsiDatetoPrettyDate $comment_date]"
	append comment_html "</blockquote>\n"
    }
    append comment_html "
    <center>
    <A HREF=\"comment-add?[export_url_vars neighbor_to_neighbor_id]\">Add a comment</a>
    </center>
    "
    append page_content $comment_html 
} else {
    # we're not soliciting comments
}


append page_content "
<hr>
</body>
</html>
"


doc_return  200 text/html $page_content
