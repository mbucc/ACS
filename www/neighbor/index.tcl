# $Id: index.tcl,v 3.0.4.1 2000/04/28 15:11:13 carsten Exp $
if { [ad_parameter OnlyOnePrimaryCategoryP neighbor 0] && ![empty_string_p [ad_parameter DefaultPrimaryCategory neighbor]] } {
    # this is only one category; send them straight there
    ad_returnredirect "opc.tcl?category_id=[ad_parameter DefaultPrimaryCategory neighbor]"
    return
}

set db [neighbor_db_gethandle]

ReturnHeaders

ns_write "[neighbor_header [neighbor_system_name]]

<h2>Neighbor to Neighbor</h2>

in [ad_site_home_link] 

<hr>

<ul>
"

set selection [ns_db select $db "select category_id, primary_category 
from n_to_n_primary_categories
where (active_p = 't' or active_p is null)
order by upper(primary_category)"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    ns_write "<li><a href=\"opc.tcl?category_id=$category_id\">$primary_category</a>\n"
}


ns_write "
</ul>

[neighbor_footer]
"



