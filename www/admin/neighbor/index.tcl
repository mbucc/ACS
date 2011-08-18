# $Id: index.tcl,v 3.0 2000/02/06 03:26:04 ron Exp $
ReturnHeaders

ns_write "[ad_admin_header "[neighbor_system_name]"]

<h2>Neighbor to Neighbor Admin</h2>

[ad_admin_context_bar "Neighbor to Neighbor"]

<hr>

<ul>
<h4>Active categories</h4>
"

set db [neighbor_db_gethandle]

set selection [ns_db select $db "select primary_category, category_id, active_p from  n_to_n_primary_categories
order by active_p desc, upper(primary_category)"]

set count 0


set count 0
set inactive_title_shown_p 0

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { $active_p == "f" } {
	if { $inactive_title_shown_p == 0 } {
	    # we have not shown the inactive title yet
	    if { $count == 0 } {
		ns_write "<li>No active categories"
	    }
	    set inactive_title_shown_p 1
	    ns_write "<h4>Inactive categories</h4>"
	}
	set anchor "activate"
    } else {
	set anchor "deactivate"
    }

    set_variables_after_query

    ns_write "<li><a href=\"category.tcl?[export_url_vars category_id]\">$primary_category</a>  (<a href=\"category-toggle.tcl?[export_url_vars category_id]\">$anchor</a>)\n"
    incr count
}

ns_write "
<p>
<li><A href=\"category-add.tcl\">Add a category</a>
</ul>

[ad_admin_footer]

"


