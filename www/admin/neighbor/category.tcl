# $Id: category.tcl,v 3.0 2000/02/06 03:26:02 ron Exp $
set_form_variables

# category_id

set db [ns_db gethandle]

set selection [ns_db 1row $db "select
* from n_to_n_primary_categories where
category_id = $category_id"]
set_variables_after_query

ReturnHeaders

ns_write "[ad_admin_header "$primary_category"]

<h2>$primary_category</h2>

[ad_admin_context_bar [list "index.tcl" "Neighbor to Neighbor"] "One Category"]


<hr>

<h3>Statistics</h3>

<ul>

"

set selection [ns_db 1row $db "select 
  to_char(count(*),'999G999G999G999') as n_postings, 
  max(posted) as latest, 
  min(posted) as earliest
from neighbor_to_neighbor
where category_id = $category_id
and (expires > sysdate or expires is NULL)"]
set_variables_after_query

ns_write "
<li>Total postings:  <a href=\"category-posts.tcl?category_id=$category_id\">$n_postings</a>
<li>From:  [util_AnsiDatetoPrettyDate $earliest]
<li>To:  [util_AnsiDatetoPrettyDate $latest]

<p>

<li>User page:  <a href=\"/neighbor/opc.tcl?category_id=$category_id\">/neighbor/opc.tcl?category_id=$category_id</a>
</ul>


<h3>Administration</h3>

<p>
Users will be asked to post in the 
following subcategories:

<ul>

"

set selection [ns_db select $db "select subcategory_id, subcategory_1
from n_to_n_subcategories
where category_id = $category_id
order by upper(subcategory_1)"]

set count 0

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    ns_write "<li><a href=\"subcategory-update.tcl?[export_url_vars subcategory_id]\">$subcategory_1</a>"
    incr count
}

if { $count == 0 } {
    ns_write "No subcategories found"
}

ns_write "<p>
<li><A href=\"subcategory-update.tcl?[export_url_vars category_id]\">Add a subcategory</a>

<p>
<li><A href=\"category-administrator-update.tcl?[export_url_vars category_id]\">Update $primary_category administrator</a>
<li><A href=\"category-update.tcl?[export_url_vars category_id]\">Update $primary_category category parameters</a>
</ul>

[ad_admin_footer]

"
