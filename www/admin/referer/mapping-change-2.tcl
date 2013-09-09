# /www/admin/referer/mapping-change-2.tcl
#

ad_page_contract {
    @param glob_pattern
    @param new_glob_pattern
    @param canonical_foreign_url
    @param search_engine_name
    @param search_engine_regexp
    @cvs-id mapping-change-2.tcl,v 3.3.2.6 2000/08/04 23:10:24 kevin Exp
} {
    glob_pattern:notnull 
    new_glob_pattern:notnull
    canonical_foreign_url:notnull
    search_engine_name:notnull
    search_engine_regexp:notnull
    submit
} -errors {
    glob_pattern {Please enter a pattern to use to lump URL's together}
    canonical_foreign_url {Please enter a URL to group the matches under.}
}


if { [string  match "*delete*" [string tolower $submit]] } {
    # user asked to delete
    db_dml referer_log_glob_delete "delete from referer_log_glob_patterns where glob_pattern= :glob_pattern"
} else {
    db_dml referer_log_glob_update "update referer_log_glob_patterns
set glob_pattern = :new_glob_pattern, 
canonical_foreign_url = :canonical_foreign_url,
search_engine_name = :search_engine_name,
search_engine_regexp = :search_engine_regexp
where glob_pattern= :glob_pattern"
}

ad_returnredirect "mapping"

