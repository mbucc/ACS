# /www/admin/neighbor/category.tcl
ad_page_contract {
    Displays a neighbor-to-neighbor category.

    @author Philip Greenspun (philg@mit.edu)
    @creation-date 1 January 1996
    @cvs-id category.tcl,v 3.3.2.3 2000/09/22 01:35:42 kevin Exp
    @param category_id the category ti display
} {
    category_id:notnull,integer
}

db_1row select_category "
  select * 
    from n_to_n_primary_categories 
   where category_id = :category_id"


set page_content "[ad_admin_header "$primary_category"]

<h2>$primary_category</h2>

[ad_admin_context_bar [list "" "Neighbor to Neighbor"] "One Category"]

<hr>

<h3>Statistics</h3>

<ul>

"

db_1row select_statistics "
  select to_char(count(*),'999G999G999G999') as n_postings, 
         max(posted) as latest, 
         min(posted) as earliest
    from neighbor_to_neighbor
   where category_id = :category_id
     and (expires > sysdate or expires is NULL)"

append page_content "
<li>Total postings:  <a href=\"category-posts?category_id=$category_id\">$n_postings</a>
<li>From:  [util_AnsiDatetoPrettyDate $earliest]
<li>To:  [util_AnsiDatetoPrettyDate $latest]

<p>

<li>User page:  <a href=\"/neighbor/opc?category_id=$category_id\">/neighbor/opc?category_id=$category_id</a>
</ul>

<h3>Administration</h3>

<p>
Users will be asked to post in the 
following subcategories:

<ul>

"

set sql_query "
    select subcategory_id, subcategory_1
      from n_to_n_subcategories
     where category_id = :category_id
  order by upper(subcategory_1)"

db_foreach select_subcategories $sql_query {
    append page_content "<li><a href=\"subcategory-update?[export_url_vars subcategory_id]\">$subcategory_1</a>"
} if_no_rows {
    append page_content "No subcategories found"
}

append page_content "<p>
<li><A href=\"subcategory-update?[export_url_vars category_id]\">Add a subcategory</a>

<p>
<li><A href=\"category-administrator-update?[export_url_vars category_id]\">Update $primary_category administrator</a>
<li><A href=\"category-update?[export_url_vars category_id]\">Update $primary_category category parameters</a>
</ul>

[ad_admin_footer]

"

db_release_unused_handles
doc_return 200 text/html $page_content
