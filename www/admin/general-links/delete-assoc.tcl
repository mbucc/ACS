# File: /admin/general-links/delete-assoc.tcl
# Date: 2/01/2000
# Author: tzumainn@arsdigita.com 
#
# Purpose: 
# Step 1 of 2 in deleting a link association
#
# $Id: delete-assoc.tcl,v 3.0 2000/02/06 03:23:37 ron Exp $
#--------------------------------------------------------

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

ad_page_variables {map_id {return_url ""}}

set db [ns_db gethandle]

set selection [ns_db 0or1row $db "select slm.link_id, on_which_table, on_what_id, one_line_item_desc, url, link_title
from site_wide_link_map slm, general_links gl
where map_id = $map_id
and slm.link_id = gl.link_id
"]

if { $selection == "" } {
   ad_return_error "Can't find link association" "Can't find link association $map_id"
   return
}

set_variables_after_query

if {[empty_string_p $return_url]} {
    set return_url "view-associations.tcl?link_id=$link_id"
}

ns_return 200 text/html "[ad_header "Confirm Link Association Deletion"]

<h2>Confirm Link Association Deletion</h2>

<hr>

Do you really wish to delete the following link association?
<blockquote>
$on_which_table: $on_what_id - $one_line_item_desc - links to: <a href=\"$url\">$link_title</a> ($url)
</blockquote>

<ul>
<li><a href=\"delete-assoc-2.tcl?[export_url_vars map_id return_url]\">Yes</a>
<li><a href=$return_url>No</a>
</ul>

[ad_footer]
"