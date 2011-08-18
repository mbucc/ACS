# $Id: search.tcl,v 3.0 2000/02/06 03:54:22 ron Exp $
ad_page_variables {query_string {sections -multiple-list}}

set exception_text ""
set exception_count 0

if { ![info exists sections] || [llength $sections] == 0 } {
    append exception_text "<li>You must specify at least one section of [ad_system_name] to search.\n"
    incr exception_count
}

if { ![info exists query_string] || [empty_string_p [string trim $query_string]] } {
    append exception_text "<li>You didn't specify a query to search for.\n"
    incr exception_count
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

# Figure out user preference for section display.
set search_display_preference [ad_search_display_preference]

if { $search_display_preference == "by_section" } {
    set order_clause "order by section_name, 1 desc"
} else {
    set order_clause "order by 1 desc"
}

## Restrict to selected sections.
set n_sections [llength $sections]

# Technically, Oracle can handle in clauses with a single value,
# but that's just not kosher ANSI.
if { $n_sections == 1 } {
    set sections_clause "and sws.table_name = '[DoubleApos $sections]'"
} else {
    set quoted_sections [list]
    foreach s $sections {
	lappend quoted_sections "'[DoubleApos $s]'"
    }
    set sections_clause "and sws.table_name in ([join $quoted_sections ", "])"
}

set db [ns_db gethandle]

set final_query_string [DoubleApos [database_to_tcl_string $db "select im_convert('[string trim [DoubleApos $query_string]]') from dual"]]

with_catch errmsg {
    set selection [ns_db select $db "select /*+ FIRST_ROWS */ score(10) as the_score, section_name, user_url_stub, the_key, one_line_description, sws.table_name
from site_wide_index sws, table_acs_properties m
where sws.table_name = m.table_name
and contains(sws.datastore, '$final_query_string', 10) > 0
$sections_clause
$order_clause"]
} {
    ad_return_error "Problem with interMedia" "There was a problem with interMedia 
while processing your query. This site wide search thing is still somewhat experimental,
so please bear with us while we work out the kinks. You may have better luck if you change
your query a little bit."
    return
}

set search_results ""

set counter 0
set last_section ""
set max_score 0

set results_base_url [ad_parameter BounceResultsTo site-wide-search ""]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    incr counter

    if { $section_name != $last_section } {
	set max_score $the_score
	# Reset count for new section.
	set counter 0
	set last_section $section_name
	append search_results "<h3>$section_name</h3>\n"
    }
    
    if { [ad_search_results_cutoff $counter $the_score $max_score] } {
	if { $search_display_preference == "by_section" } {
	    # We may have more sections later on.
	    continue
	} else {
	    # All done.
	    ns_db flush $db
	    break
	}
    }

    set one_line "<li>$the_score: <a href=\"$results_base_url$user_url_stub$the_key\">$one_line_description</a>\n"
    if { $n_sections > 1 && $search_display_preference == "one_list" } {
	append search_results "$one_line <font size=-1>($section_name)</font>\n"
    } else {
	append search_results $one_line
    }
    
    append search_results "<font size=-1>(<a href=\"query-by-example.tcl?subject=[ns_urlencode $one_line_description]&[export_url_vars table_name the_key sections]\">more like this</a>)</font>\n"
}

if { [empty_string_p $search_results] } {
    set search_results "No hits found for your query."
}

set site_search_widget "<form action=\"search.tcl\" method=GET>
[ad_site_wide_search_widget $db $query_string $sections]
</form>
"

ad_record_query_string $query_string $db $sections $counter [ad_get_user_id]

ns_db releasehandle $db



ns_return 200 text/html "[ad_header "Search Results"]

<h2>Search Results</h2>

[ad_context_bar_ws_or_index [list "index.tcl" "Search"] "Results"]

<hr>

Results for \"$query_string\":

<ul>
$search_results
</ul>

$site_search_widget

[ad_footer]
"

