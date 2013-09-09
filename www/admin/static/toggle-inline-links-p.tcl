ad_page_contract {
    toggle-inline-links-p.tcl,v 3.1.6.3 2000/07/21 03:58:09 ron Exp
} {
    page_id:integer
}

db_dml static_toggle_inline_links_update "update static_pages 
set inline_links_p = logical_negation(inline_links_p) where page_id = :page_id"

db_release_unused_handles

ad_returnredirect "page-summary.tcl?[export_url_vars page_id]"
