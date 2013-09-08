# /www/neighbor/post-new.tcl
ad_page_contract {
    Post new items into a category.

    @param category_id the id of the category to put the post into.
    @author Philip Greenspun (philg@mit.edu)
    @creation-date 1 January 1996
    @cvs-id post-new.tcl,v 3.4.2.4 2000/09/22 01:38:56 kevin Exp
} {
    category_id:integer
}

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

#check for the user cookie

set user_id [ad_get_user_id]

if {$user_id == 0} {
   ad_returnredirect /register/?return_url=[ns_urlencode "[ns_conn url]?[export_url_vars category_id]"]
   return
}

# we know who this is


set query_result [db_0or1row n_to_n_category_info_2 "select primary_category, pre_post_blurb, primary_maintainer_id, u.email as maintainer_email
from n_to_n_primary_categories n, users u 
where n.primary_maintainer_id = u.user_id
and n.category_id = :category_id"]

if [empty_string_p $query_result] {
    ad_return_error "Couldn't find Category $category_id" "There is no category
$category_id\" in [neighbor_system_name]"
    return
}

set page_content "[neighbor_header "Prepare New Post"]

<h2>Prepare a New Posting</h2>

in [neighbor_home_link $category_id $primary_category]

<hr>
<h3>Pick a Category</h3>

<ul>

"

set sql_query "select subcategory_id, subcategory_1
from n_to_n_subcategories
where category_id = :category_id"

db_foreach n_to_n_subcategory_list $sql_query {
    append page_content "<li><a href=\"post-new-2?subcategory_id=$subcategory_id\">$subcategory_1</a>\n"
}

db_release_unused_handles

append page_content "

</ul>

$pre_post_blurb

[neighbor_footer $maintainer_email]
"

doc_return  200 text/html $page_content