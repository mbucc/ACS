# $Id: query-by-example.tcl,v 3.0 2000/02/06 03:54:21 ron Exp $
set_the_usual_form_variables
# table_name, the_key, sections, subject


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


# Get themes for this document.
set themes [ad_search_qbe_get_themes $table_name $the_key]


set db [ns_db gethandle]

# generate about portion of the search query.
set about_clause [list]

foreach theme $themes {
    lappend about_clause "about($theme)"
}

regsub -all {\)} $QQsubject "" subject_for_context

# Throw in the subject line to increase relevance.
set subject_query [database_to_tcl_string $db "select im_convert('$subject_for_context') from dual"]

set selection [ns_db select $db "select /*+ FIRST_ROWS */ score(10) as the_score, section_name, user_url_stub, the_key, one_line_description, sws.table_name
from site_wide_index sws, table_acs_properties m
where sws.table_name = m.table_name
and contains(sws.datastore, '$subject_query and [join $about_clause " and "]', 10) > 0
$sections_clause
$order_clause"]

ReturnHeaders

ns_write "[ad_header "Search Results"]

<h2>Search Results</h2>

[ad_context_bar_ws_or_index [list "index.tcl" "Search"] "Results"]

<hr>

Themes searched for: [join $themes ", "]

<ul>
"

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
	ns_db flush $db
	break
    }

    set one_line "<li>$the_score: <a href=\"$results_base_url$user_url_stub$the_key\">$one_line_description</a>\n"
    if { $n_sections > 1 && $search_display_preference == "one_list" } {
	append search_results "$one_line <font size=-1>($section_name)</font>\n"
    } else {
	append search_results $one_line
    }

    append search_results "(<a href=\"query-by-example.tcl?subject=[ns_urlencode $one_line_description]&[export_url_vars table_name the_key sections]\">more like this</a>)\n"
}


ns_db releasehandle $db

ns_write "$search_results
</ul>


[ad_footer]
"
