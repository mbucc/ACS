# /www/admin/referer/mapping-add-2.tcl
#

ad_page_contract {
    @param glob_pattern
    @param canonical_foreign_url
    @cvs-id mapping-add-2.tcl,v 3.4.2.6 2000/08/04 23:09:25 kevin Exp
} {
    glob_pattern:notnull
    canonical_foreign_url:notnull
    search_engine_name:notnull
    search_engine_regexp:notnull
} -errors {
    glob_pattern {Please enter a pattern to use to lump URL's together}
    canonical_foreign_url {Please enter a URL to group the matches under.}
}


if [catch { db_dml referrer_mapping_insert "
insert into referer_log_glob_patterns
(glob_pattern, canonical_foreign_url, search_engine_name, search_engine_regexp)
values
(:glob_pattern, :canonical_foreign_url, :search_engine_name,
 :search_engine_regexp)"} errmsg] {

    set n_already [db_string referer_log_glop_pattern_count "select count(*) from referer_log_glob_patterns where glob_pattern = :glob_pattern"]
    if { $n_already > 0 } {
	ad_return_error "There is already a mapping for $glob_pattern" "There is already a mapping for the pattern \"$glob_pattern\".
If you didn't hit submit twice by mistake, then perhaps
what you want to do is <a href=\"mapping-change?[export_url_vars glob_pattern]."
    } else  {
	ad_return_error "Failured to add mapping" "The database rejected the insert:
<blockquote>
<pre>
$errmsg
</pre>
</blockquote>
"
    }
    return
} 

ad_returnredirect "mapping"




