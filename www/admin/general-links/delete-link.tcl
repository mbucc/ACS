# File: /admin/general-links/delete-link.tcl
# Date: 2/01/2000
# Author: tzumainn@arsdigita.com 
#
# Purpose: 
# Step 1 of 2 in deleting a link and everything associated with it
#
# $Id: delete-link.tcl,v 3.0 2000/02/06 03:23:40 ron Exp $
#--------------------------------------------------------

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

ad_page_variables {link_id {return_url "index.tcl"}}

set db [ns_db gethandle]

set selection [ns_db 0or1row $db "select link_id, url, link_title, link_description
from general_links
where link_id = $link_id"]

if { $selection == "" } {
   ad_return_error "Can't find link" "Can't find link $link_id"
   return
}

set_variables_after_query

set selection [ns_db select $db "select on_which_table, on_what_id, one_line_item_desc from site_wide_link_map where link_id = $link_id"]

set n_assoc 0
set assoc_list "<ul>"
while {[ns_db getrow $db $selection]} {
    incr n_assoc
    set_variables_after_query
    
    append assoc_list "<li><b>$on_which_table</b>: $on_what_id - $one_line_item_desc"    
}

ns_db releasehandle $db

if { $n_assoc == 0 } {
    append assoc_list "<li>This link has no associations."
}
append assoc_list "</ul>"

ns_return 200 text/html "[ad_header "Confirm Link Deletion" ]

<h2>Confirm Link Deletion</h2>

<hr>

Do you really wish to delete the following link?
<blockquote>
<a href=\"$url\">$link_title</a> ($url)
<br>$link_description
<p>
<ul>
<li>All associations with this link will be deleted as well: $assoc_list
</ul>
</blockquote>

<ul>
<li><a href=\"delete-link-2.tcl?[export_url_vars link_id return_url]\">Yes</a>
<li><a href=\"\">No</a>
</ul>

[ad_footer]
"
