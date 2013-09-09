ad_page_contract {
    delete-one-2.tcl,v 3.1.6.3 2000/07/21 03:58:09 ron Exp
} {
    exclusion_pattern_id:integer
}

db_dml static_exclusion_delete_one "delete from static_page_index_exclusion
where exclusion_pattern_id = :exclusion_pattern_id"

db_release_unused_handles

ad_returnredirect "../index.tcl"
