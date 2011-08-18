# $Id: index.tcl,v 3.0 2000/02/06 03:26:15 ron Exp $
set db [neighbor_db_gethandle]

ReturnHeaders

ns_write "[neighbor_header [neighbor_system_name]]

<h2>Neighbor to Neighbor Admin</h2>

<hr>

<h3>Lumpen Categorization</h3>

<ul>

"


    set selection [ns_db select $db "select count(neighbor_to_neighbor_id) as count,subcategory_1
from neighbor_to_neighbor
where domain = 'photo.net'
and primary_category = 'photographic' 
group by subcategory_1
order by subcategory_1"]

    while {[ns_db getrow $db $selection]} {

	set_variables_after_query
	set url "lump-into-about.tcl?subcategory_1=[ns_urlencode $subcategory_1]"
	ns_write "<li><a href=\"$url\">$subcategory_1</a> ($count postings)"
    }

ns_write "

</ul>

[neighbor_footer]

"


