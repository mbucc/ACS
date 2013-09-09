# /www/neighbor/post-new-4.tcl
ad_page_contract {
    Posts new entries into a given category.

    @author Philip Greenspun (philg@mit.edu)
    @creation-date 1 January 1998
    @cvs-id post-new-4.tcl,v 3.4.2.4 2000/09/22 01:38:55 kevin Exp
    @param subcategory_id the category to post into
    @param about what the post is about
    @param title a short, one-line title
    @param body the body of the post
    @param html_p whether the body is html or plaintext
} {
    subcategory_id:integer,notnull
    about:notnull
    title:notnull
    body:notnull,html
    html_p:notnull
}

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

#check for the user cookie

set user_id [ad_maybe_redirect_for_registration]

# we know who this is


set sql_query "
  select n.category_id, n.noun_for_about, primary_category, subcategory_1, 
         pre_post_blurb, primary_maintainer_id, u.email as maintainer_email
    from n_to_n_subcategories sc, n_to_n_primary_categories n, users u 
   where sc.category_id = n.category_id
     and n.primary_maintainer_id = u.user_id
     and sc.subcategory_id = :subcategory_id"

if {![db_0or1row select_category $sql_query]} {
    db_release_unused_handles
    ad_return_error "Couldn't find Subcategory $subcategory_id" "There is no subcategory
$subcategory_id\" in [neighbor_system_name]"
    return
}

set exception_text ""
set exception_count 0

if { [info exists title] && $title != "" && ![regexp {[a-z]} $title] } {
    append exception_text "<li>Your one line summary appears to be all uppercase.  ON THE INTERNET THIS IS CONSIDERED SHOUTING.  IT IS ALSO MUCH HARDER TO READ THAN MIXED CASE TEXT.  So we don't allow it, out of decorum and consideration for people who may be visually impaired."
    incr exception_count
}

if { [info exists body] && $body != "" && ![regexp {[a-z]} $body] } {
    append exception_text "<li>Your story appears to be all uppercase.  ON THE INTERNET THIS IS CONSIDERED SHOUTING.  IT IS ALSO MUCH HARDER TO READ THAN MIXED CASE TEXT.  So we don't allow it, out of decorum and consideration for people who may be visually impaired."
    incr exception_count
}

if { $exception_count != 0 } {
    db_release_unused_handles
    ad_return_complaint $exception_count $exception_text
    return
}

if { $exception_count != 0 } {
    
    doc_return  200 text/html [neighbor_error_page $exception_count $exception_text]
    return
}

# no exceptions

set page_content "[neighbor_header "Previewing Story"]

<h2>Previewing Story</h2>

before stuffing it into [neighbor_home_link $category_id $primary_category]

<hr>

<h3>What viewers of a summary list will see</h3>

$about : $title

<h3>The full story</h3>

<blockquote>
"

if { [info exists html_p] && $html_p == "t" } {
    append page_content "$body
</blockquote>

Note: if the story has lost all of its paragraph breaks then you
probably should have selected \"Plain Text\" rather than HTML.  Use
your browser's Back button to return to the submission form.
"

} else {
    append page_content "[util_convert_plaintext_to_html $body]
</blockquote>

Note: if the story has a bunch of visible HTML tags then you probably
should have selected \"HTML\" rather than \"Plain Text\".  Use your
browser's Back button to return to the submission form.  " 
}

append page_content "
</blockquote>

"

set neighbor_to_neighbor_id [db_string get_id "
  select neighbor_sequence.nextval 
    from dual"]

append page_content "
<form method=POST action=post-new-5>
[export_form_vars neighbor_to_neighbor_id]
[export_entire_form]
<center>
<input type=submit value=\"Confirm\">
</center>
</form>

[neighbor_footer $maintainer_email]
"

db_release_unused_handles
doc_return 200 text/html $page_content