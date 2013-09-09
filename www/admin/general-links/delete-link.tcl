# File: /admin/general-links/delete-link.tcl

ad_page_contract {
    Step 1 of 2 in deleting a link and everything associated with it

    @param link_id The ID of the link to delete
    @param return_url Where to go when finished with deleting

    @author Tzu-Mainn Chen (tzumainn@arsdigita.com)
    @creation-date 2/01/2000
    @cvs-id delete-link.tcl,v 3.1.6.6 2000/09/22 01:35:25 kevin Exp
} {
    link_id:notnull,naturalnum
    {return_url "index"}
}

#--------------------------------------------------------

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

if { ![db_0or1row select_one_link_info "select link_id, url, link_title, link_description
from general_links
where link_id = :link_id"] } {
   ad_return_error "Can't find link" "Can't find link $link_id"
   return
}

set sql_qry "select on_which_table, on_what_id, one_line_item_desc from site_wide_link_map where link_id = :link_id"

set assoc_list "<ul>"
db_foreach print_link_info $sql_qry {
    append assoc_list "<li><b>$on_which_table</b>: $on_what_id - $one_line_item_desc"    
} if_no_rows {
    append assoc_list "<li>This link has no associations."
}

db_release_unused_handles

append assoc_list "</ul>"

doc_return  200 text/html "[ad_header "Confirm Link Deletion" ]

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
<li><a href=\"delete-link-2?[export_url_vars link_id return_url]\">Yes</a>
<li><a href=\"\">No</a>
</ul>

[ad_footer]
"
