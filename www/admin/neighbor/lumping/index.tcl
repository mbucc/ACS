# /www/admin/neighbor/lumping/index.tcl
ad_page_contract {
    Lumps categories.

    @author Philip Greenspun (philg@mit.edu)
    @creation-date 1 January 1996
    @cvs-id index.tcl,v 3.2.2.2 2000/09/22 01:35:43 kevin Exp
} {}

set page_content "[neighbor_header [neighbor_system_name]]

<h2>Neighbor to Neighbor Admin</h2>

<hr>

<h3>Lumpen Categorization</h3>

<ul>

"

set sql_query "
    select count(neighbor_to_neighbor_id) as count,subcategory_1
      from neighbor_to_neighbor
     where domain = 'photo.net'
       and primary_category = 'photographic' 
  group by subcategory_1
  order by subcategory_1"

db_foreach select_categories $sql_query {
    set url "lump-into-about?subcategory_1=[ns_urlencode $subcategory_1]"
    append page_content "<li><a href=\"$url\">$subcategory_1</a> ($count postings)"
}

append page_content "

</ul>

[neighbor_footer]

"

db_release_unused_handles
doc_return 200 text/html $page_content