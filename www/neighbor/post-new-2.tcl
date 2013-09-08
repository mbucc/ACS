# /www/neighbor/post-new-2.tcl
ad_page_contract {
    Posts new items into a category.

    @author Philip Greenspun (philg@mit.edu)
    @creation-date 1 January 1998
    @cvs-id post-new-2.tcl,v 3.4.2.4 2000/09/22 01:38:55 kevin Exp
    @param subcategory_id the category to post into
} {
    subcategory_id:integer,notnull
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

set page_content "[neighbor_header "Post Step 2"]

<h2>Step 2</h2>

of posting a new $subcategory_1  story in [neighbor_home_link $category_id $primary_category]

<hr>

In order to keep the site easily browsable, if you're telling a story
about the same $noun_for_about as a previous poster,
then it would be good if you click on the name here rather than typing
it again (because you'd probably spell it differently).

<ul>

"

set sql_query "
    select distinct about
      from neighbor_to_neighbor
     where subcategory_id = :subcategory_id
       and about is not null
  order by upper(about)"

db_foreach select_abouts $sql_query {
    append page_content "<li><a href=\"post-new-3?subcategory_id=$subcategory_id&about=[ns_urlencode $about]\">$about</a>\n"
} if_no_rows {
    append page_content "no existing items found"
}

append page_content "
</ul>

<P>

Just click on one of the above names if you recognize it.  If not,
e.g., if you are telling a story about a new $noun_for_about, then 
enter the name here:

<form method=post action=post-new-3>
[export_form_vars subcategory_id]
<input type=text name=about size=20>
<input type=submit value=\"Add a new About Value to the Database\">
</form>
"

append page_content "[neighbor_footer $maintainer_email]"


doc_return  200 text/html $page_content