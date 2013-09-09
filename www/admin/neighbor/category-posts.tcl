# /www/admin/neighbor/category-posts.tcl
ad_page_contract {
    Shows the postings in a given category.

    @author Philip Greenspun (philg@mit.edu)
    @creation-date 1 January 1996
    @cvs-id category-posts.tcl,v 3.3.2.3 2000/09/22 01:35:41 kevin Exp
    @param category_id the ID of the category to change
    @param all_p if 1, show all postings, else limit to the last 30 days
} {
    category_id:notnull,integer
    all_p:optional
}

if { [info exists all_p] && $all_p } {
    set extra_stipulation ""
    set new_clause ""
    set option "<a href=\"category-posts?all_p=0&category_id=$category_id\">limit to last 30 days</a>"
} else {
    set extra_stipulation "within the last 30 days "
    set new_clause "\nand posted > sysdate - 30"
    set option "<a href=\"category-posts?all_p=1&category_id=$category_id\">view all postings</a>"
}



set primary_category [db_string select_category_name "
  select primary_category
    from n_to_n_primary_categories 
   where category_id = :category_id"]

set page_content "[ad_admin_header "$primary_category postings"]

<h2>Postings</h2>

$extra_stipulation

<P>

[ad_admin_context_bar [list "" "Neighbor to Neighbor"] [list "category?[export_url_vars category_id]" "One Category"] "Postings"]

<hr>

$option

<ul>
"

set sql_query "
    select neighbor_to_neighbor_id, title, posted, about, 
           upper(about) as sort_key, nn.approved_p, nns.subcategory_1, 
           users.user_id, 
           users.first_names || ' ' || users.last_name as poster_name
      from neighbor_to_neighbor nn, n_to_n_subcategories nns, users
     where nn.category_id = :category_id
       and nn.subcategory_id = nns.subcategory_id
       and (expires > sysdate or expires is NULL) $new_clause
       and nn.poster_user_id = users.user_id
  order by posted desc"

set counter 0 
set items ""

db_foreach select_posts $sql_query {
    incr counter 
    if [empty_string_p $title] {
	set anchor $about
    } else {
	set anchor "$about : $title"
    }
    append items "<li><a href=\"view-one?neighbor_to_neighbor_id=$neighbor_to_neighbor_id\">$anchor</a>" 
    if { $approved_p == "f" } {
	append items "&nbsp; <font color=red>not approved</font>"
    }
    append items " <font size=-1>($subcategory_1)</font>\n"
}

append page_content "$items

</ul>

[ad_admin_footer]
"

db_release_unused_handles
doc_return 200 text/html $page_content