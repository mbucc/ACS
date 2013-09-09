# /www/neighbor/post-new-3.tcl
ad_page_contract {
    Posts new entries into a given category.

    @author Philip Greenspun (philg@mit.edu)
    @creation-date 1 January 1998
    @cvs-id post-new-3.tcl,v 3.4.2.3 2000/09/22 01:38:55 kevin Exp
    @param subcategory_id the category to post into
    @param about what the entry is about
} {
    subcategory_id:integer,notnull
    about:notnull
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
    db_releas_unused_handles
    ad_return_error "Couldn't find Subcategory $subcategory_id" "There is no subcategory
$subcategory_id\" in [neighbor_system_name]"
    return
}

set page_content "[neighbor_header "Post Step 3"]

<h2>Step 3</h2>

of posting a new $subcategory_1 story in [neighbor_home_link $category_id $primary_category]

<hr>

<form method=post action=post-new-4>
[export_form_vars subcategory_id about]

<p>

Give us a one-line summary of your posting, something that will let
someone know whether or not they want to read the full story.  Note
that this will appear with the about field (\"$about\") in front of
it, so you don't have to repeat the name of the merchant, camera, etc.

<p>

$about : <input type=text name=title size=50>

<p>

Give us the full story, taking as much space as you need.

<p>

<textarea name=body rows=8 cols=70 wrap=soft>

</textarea>

<br>

The above story is in <select name=html_p><option value=f>Plain Text<option value=t>HTML</select>

<p>

<center>
<input type=submit value=\"Preview Story\">
</center>

[neighbor_footer]
"

db_release_unused_handles
doc_return 200 text/html $page_content
