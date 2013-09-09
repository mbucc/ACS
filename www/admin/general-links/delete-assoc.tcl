# File: /admin/general-links/delete-assoc.tcl

ad_page_contract {
    Step 1 of 2 in deleting a link association

    @param map_id The ID of the association to delete
    @param return_url Where to go one finished deleting

    @author Tzu-Mainn Chen (tzumainn@arsdigita.com)
    @creation-date 2/01/2000
    @cvs-id delete-assoc.tcl,v 3.1.6.7 2000/09/22 01:35:25 kevin Exp
} {
    map_id:notnull,naturalnum
    {return_url ""}
}

#--------------------------------------------------------

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

if {![db_0or1row select_assoc_info "select slm.link_id, on_which_table, on_what_id, one_line_item_desc, url, link_title
from site_wide_link_map slm, general_links gl
where map_id = :map_id
and slm.link_id = gl.link_id
"]} {
   ad_return_error "Can't find link association" "Can't find link association $map_id"
   return
}

db_release_unused_handles

if {[empty_string_p $return_url]} {
    set return_url "view-associations?link_id=$link_id"
}

doc_return  200 text/html "[ad_header "Confirm Link Association Deletion"]

<h2>Confirm Link Association Deletion</h2>

<hr>

Do you really wish to delete the following link association?
<blockquote>
$on_which_table: $on_what_id - $one_line_item_desc - links to: <a href=\"$url\">$link_title</a> ($url)
</blockquote>

<ul>
<li><a href=\"delete-assoc-2?[export_url_vars map_id return_url]\">Yes</a>
<li><a href=$return_url>No</a>
</ul>

[ad_footer]
"