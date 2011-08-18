# $Id: site-wide-search-defs.tcl,v 3.0 2000/02/06 03:14:02 ron Exp $
#
# /tcl/site-wide-search-defs.tcl
#
# by jsc@arsdigita.com, late 1999
#

util_report_library_entry

proc_doc ad_search_results_cutoff { nth_row current_score max_score } {
    Returns 1 to indicate that a search result should be cut off, based on
    a heuristic measure of current relevance vs. number of rows
    already returned.
} {
    if { ($nth_row > 25) && ($current_score < [expr 0.3 * $max_score] ) } {
	# we've gotten more than 25 rows AND our relevance score
	# is down to 30% of what the maximally relevant row was
	return 1
    }
    if { ($nth_row > 50) && ($current_score < [expr 0.5 * $max_score] ) } {
	# take a tougher look
	return 1
    }
    if { ($nth_row > 100) && ($current_score < [expr 0.8 * $max_score] ) } {
	# take a tougher look yet
	return 1
    }
    return 0
}

proc ad_site_wide_search_widget {db {query_string ""} {sections_list ""} {prompt "Search entire site"}} {
    set selection [ns_db select $db "select section_name, table_name
from table_acs_properties
where table_name in ('bboard', 'static_pages', 'comments')
order by section_name"]

    set widget ""

    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	
	if { [lsearch -exact $sections_list $table_name] >= 0 } {
	    set checked " checked"
	} else {
	    set checked ""
	}
	append widget "<input type=checkbox name=sections value=\"$table_name\"$checked>&nbsp;$section_name&nbsp;&nbsp;"
    }
    
    append widget "<br>\n"

    if { [empty_string_p $query_string] } {
	append widget "Search for: <input type=text size=30 name=query_string> <input type=submit value=Search>"
    } else {
	append widget "Search for: <input type=text size=30 name=query_string value=\"[philg_quote_double_quotes $query_string]\"> <input type=submit value=Search>"
    }
    return $widget
}

proc_doc ad_search_display_preference {} {
    Returns "by_section" or "one_list" to indicate user's display preference
    for site wide search. Preference is stored in a cookie, or defaults to
    "by_section".
} {
    return "by_section"
}

# Helper function for ad_search_qbe_get_themes.
proc ad_search_qbe_get_themes_helper { table_name primary_key } {
    set db [ns_db gethandle subquery]

    ns_db dml $db "begin transaction"

    ns_db dml $db "begin ctx_doc.themes('SWS_CTX_INDEX', ctx_doc.pkencode('$table_name', '$primary_key'), 'SWS_RESULT_TABLE', 1); end;"

    set selection [ns_db select $db "select theme
from sws_result_table
order by weight desc"]

    set count 0
    set themes [list]
    
    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	
	lappend themes $theme
	incr count
	if { $count == 5 } {
	    ns_db flush $db
	    break
	}
    }

    ns_db dml $db "delete from sws_result_table"
    ns_db dml $db "end transaction"
    return $themes
}

proc_doc ad_search_qbe_get_themes { table_name primary_key } {
    Return a list of themes associated with the document in the site wide index
    referenced by table_name and primary_key.
} {
    return [util_memoize "ad_search_qbe_get_themes_helper $table_name $primary_key"]
}

util_report_successful_library_load
