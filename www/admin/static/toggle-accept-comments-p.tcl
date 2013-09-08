ad_page_contract {
    toggle-accept-comments-p.tcl,v 3.1.6.3 2000/07/21 03:58:08 ron Exp
} {
    page_id:integer
}

db_dml static_update_static_pages "update static_pages 
set accept_comments_p = logical_negation(accept_comments_p) 
where page_id = :page_id"

db_release_unused_handles

ad_returnredirect "page-summary.tcl?[export_url_vars page_id]"
