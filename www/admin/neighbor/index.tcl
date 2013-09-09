# /www/admin/neighbor/index.tcl
ad_page_contract {
    The main administration page for the neighbor-to-neighbor module.

    @author Philip Greenspun (philg@mit.edu)
    @creation-date 1 January 1996
    @cvs-id index.tcl,v 3.2.2.3 2000/09/22 01:35:42 kevin Exp
} {}

set page_content "[ad_admin_header "[neighbor_system_name]"]

<h2>Neighbor to Neighbor Admin</h2>

[ad_admin_context_bar "Neighbor to Neighbor"]

<hr>

<ul>
<h4>Active categories</h4>
"

set sql_query "
    select primary_category, category_id, active_p 
      from n_to_n_primary_categories
  order by active_p desc, upper(primary_category)"

set count 0
set inactive_title_shown_p 0

db_foreach select_categories $sql_query {
    if { $active_p == "f" } {
	if { $inactive_title_shown_p == 0 } {
	    # we have not shown the inactive title yet
	    if { $count == 0 } {
		append page_content "<li>No active categories"
	    }
	    set inactive_title_shown_p 1
	    append page_content "<h4>Inactive categories</h4>"
	}
	set anchor "activate"
    } else {
	set anchor "deactivate"
    }

    append page_content "<li><a href=\"category?[export_url_vars category_id]\">$primary_category</a>  (<a href=\"category-toggle?[export_url_vars category_id]\">$anchor</a>)\n"
    incr count
}

append page_content "
<p>
<li><A href=\"category-add\">Add a category</a>
</ul>

[ad_admin_footer]

"


doc_return  200 text/html $page_content