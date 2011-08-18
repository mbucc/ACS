# $Id: mapping-change-2.tcl,v 3.0.4.1 2000/04/28 15:09:19 carsten Exp $
set_the_usual_form_variables

# glob_pattern (database key), new_glob_pattern,
# canonical_foreign_url, search_engine_name, search_engine_regexp


set exception_count 0
set exception_text ""


if { ![info exists glob_pattern] || [empty_string_p $glob_pattern] } {
    incr exception_count
    append exception_text "<li>Please enter a pattern to use to lump URL's together."
}
if { ![info exists canonical_foreign_url] || [empty_string_p $canonical_foreign_url] } {
    incr exception_count
    append exception_text "<li>Please enter a URL to group the matches under."
}


if {$exception_count > 0} { 
    ad_return_complaint $exception_count $exception_text
    return
}


set db [ns_db gethandle]

if { [string  match "*delete*" [string tolower $submit]] } {
    # user asked to delete
    ns_db dml $db "delete from referer_log_glob_patterns where glob_pattern= '$QQglob_pattern'"
} else {    
    ns_db dml $db "update referer_log_glob_patterns
set glob_pattern='$QQnew_glob_pattern', 
canonical_foreign_url='$QQcanonical_foreign_url',
search_engine_name = '$QQsearch_engine_name',
search_engine_regexp = '$QQsearch_engine_regexp'
where glob_pattern= '$QQglob_pattern'"
}

ad_returnredirect "mapping.tcl"

