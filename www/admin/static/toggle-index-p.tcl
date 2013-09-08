ad_page_contract {
    toggle-index-p.tcl,v 3.1.6.3 2000/07/21 03:58:08 ron Exp
} {
    page_id:integer
}

db_dml toggle_update_index "update static_pages
set index_p = logical_negation(index_p),
    index_decision_made_by = 'human'
where page_id = :page_id"

db_release_unused_handles

ad_returnredirect "page-summary.tcl?[export_url_vars page_id]"
