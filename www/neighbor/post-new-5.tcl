# /www/neighbor/post-new-5.tcl
ad_page_contract {
    Posts a new entry into a given category.

    @author Philip Greenspun (philg@mit.edu)
    @creation-date 1 January 1998
    @cvs-id post-new-5.tcl,v 3.3.2.4 2000/09/22 01:38:56 kevin Exp
    @param subcategory_id the category to post into
    @param about what the post is about
    @param title a short, one-line title
    @param body the body of the post
    @param html_p whether the post is HTML or plaintext
    @param neighbor_to_neighbor_id the ID of the new post
} {
    subcategory_id:integer,notnull
    about:notnull
    title:notnull
    body:notnull,html
    html_p:notnull
    neighbor_to_neighbor_id:integer,notnull
}

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

# check for the user cookie; they shouldn't ever get here

set user_id [ad_maybe_redirect_for_registration]

set sql_query "
  select n.category_id, n.noun_for_about, primary_category, subcategory_1, 
         pre_post_blurb, approval_policy, primary_maintainer_id, 
         u.email as maintainer_email
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

set page_content "[neighbor_header "Inserting Story"]

<h2>Inserting Story</h2>

into [neighbor_home_link $category_id $primary_category]

<hr>

"

set creation_ip_address [ns_conn peeraddr]

if { $approval_policy == "open" } {
    set approved_p "t"
} else {
    set approved_p "f"
}

# this used to use the clob extensions only if the string length
# was >= 4000.  why bother?  the extensions work with smaller strings,
# and the code is cleaner this way.   -- dcreager, 14-Jul-2000

# pathetic Oracle must be fed the full story via the bizzarro
# clob extensions 
db_dml insert_entry {
  insert into neighbor_to_neighbor
              (neighbor_to_neighbor_id, poster_user_id, posted, 
               creation_ip_address, category_id, subcategory_id, about, title, 
               body, html_p, approved_p)
       values (:neighbor_to_neighbor_id, :user_id, sysdate, 
               :creation_ip_address, :category_id, :subcategory_id, :about,
               :title,empty_clob(),:html_p,:approved_p)
    returning body into :1
} -clobs [list $body]

append page_content "Success!

<p>

There isn't much more to say.

[neighbor_footer $maintainer_email]
"


doc_return  200 text/html $page_content