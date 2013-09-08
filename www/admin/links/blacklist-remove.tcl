# /admin/links/blacklist-remove.tcl

ad_page_contract {
    Remove a link from the blacklist.

    @param pattern_id The ID of the pattern to remove from blacklisting

    @author Original Author Unknown
    @creation-date Original Date Unknown
    @cvs-id blacklist-remove.tcl,v 3.2.2.5 2000/07/21 03:57:27 ron Exp
} {
    pattern_id:naturalnum
}

set admin_id [ad_verify_and_get_user_id]

if { $admin_id == 0 } {
    ad_returnredirect "/register/"
    return
}

db_dml delete_pattern "delete from link_kill_patterns where pattern_id=:pattern_id"

db_release_unused_handles

ad_returnredirect blacklist-all
