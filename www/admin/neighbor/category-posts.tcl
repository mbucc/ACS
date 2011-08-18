# $Id: category-posts.tcl,v 3.0 2000/02/06 03:25:54 ron Exp $
set_form_variables

# category_id, optional all_p 

if { [info exists all_p] && $all_p } {
    set extra_stipulation ""
    set new_clause ""
    set option "<a href=\"category-posts.tcl?all_p=0&category_id=$category_id\">limit to last 30 days</a>"
} else {
    set extra_stipulation "within the last 30 days "
    set new_clause "\nand posted > sysdate - 30"
    set option "<a href=\"category-posts.tcl?all_p=1&category_id=$category_id\">view all postings</a>"
}

set db [ns_db gethandle]

set primary_category [database_to_tcl_string $db "select primary_category
from n_to_n_primary_categories where category_id = $category_id"]

ReturnHeaders

ns_write "[ad_admin_header "$primary_category postings"]

<h2>Postings</h2>

$extra_stipulation

<P>

[ad_admin_context_bar [list "index.tcl" "Neighbor to Neighbor"] [list "category.tcl?[export_url_vars category_id]" "One Category"] "Postings"]

<hr>

$option

<ul>
"


set selection [ns_db select $db "select neighbor_to_neighbor_id, title, posted, about, upper(about) as sort_key, nn.approved_p, nns.subcategory_1, users.user_id, users.first_names || ' ' || users.last_name as poster_name
from neighbor_to_neighbor nn, n_to_n_subcategories nns, users
where nn.category_id = $category_id
and nn.subcategory_id = nns.subcategory_id
and (expires > sysdate or expires is NULL) $new_clause
and nn.poster_user_id = users.user_id
order by posted desc"]

set counter 0 
set items ""

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    incr counter 
    if [empty_string_p $title] {
	set anchor $about
    } else {
	set anchor "$about : $title"
    }
    append items "<li><a href=\"view-one.tcl?neighbor_to_neighbor_id=$neighbor_to_neighbor_id\">$anchor</a>" 
    if { $approved_p == "f" } {
	append items "&nbsp; <font color=red>not approved</font>"
    }
    append items " <font size=-1>($subcategory_1)</font>\n"
}

ns_write "$items


</ul>


[ad_admin_footer]
"

