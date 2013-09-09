# /www/search/query-by-example.tcl
ad_page_contract {
    @cvs-id query-by-example.tcl,v 3.2.2.5 2000/09/22 01:39:17 kevin Exp
} {
    table_name:notnull
    the_key:notnull
    sections:multiple,notnull
    subject:notnull
}

set user_id [ad_verify_and_get_user_id]

# Figure out user preference for section display.
set search_display_preference [ad_search_display_preference]

#  if { $search_display_preference == "by_section" } {
#      set order_clause "order by section_name, 1 desc"
#  } else {
#      set order_clause "order by 1 desc"
#  }

## Restrict to selected sections.
set n_sections [llength $sections]

# Technically, Oracle can handle in clauses with a single value,
# but that's just not kosher ANSI.
if { $n_sections == 1 } {
    set sections_clause "and sws.table_name = :sections"
} else {
    set quoted_sections [list]
    foreach s $sections {
	lappend quoted_sections "'[DoubleApos $s]'"
    }
    set sections_clause "and sws.table_name in ([join $quoted_sections ", "])"
}

# Get themes for this document.
set themes [ad_search_qbe_get_themes $table_name $the_key]


# generate about portion of the search query.
set about_clause [list]

foreach theme $themes {
    lappend about_clause "about($theme)"
}

regsub -all {\)} [DoubleApos $subject] "" subject_for_context

# Throw in the subject line to increase relevance.
set subject_query [DoubleApos [db_string subject_select "select im_convert('$subject_for_context') from dual"]]

set results_base_url [ad_parameter BounceResultsTo site-wide-search ""]

#  set search_results ""

#  set selection [ns_db select $db "select /*+ FIRST_ROWS */ score(10) as the_score, section_name, user_url_stub, the_key, one_line_description, sws.table_name
#  from site_wide_index sws, table_acs_properties m
#  where sws.table_name = m.table_name
#  and contains(sws.datastore, '$subject_query and [join $about_clause " and "]', 10) > 0
#  $sections_clause
#  $order_clause"]

#  set counter 0
#  set last_section ""
#  set max_score 0

#  while {[ns_db getrow $db $selection]} {
#      set_variables_after_query
#      incr counter

#      if { $section_name != $last_section } {
#  	set max_score $the_score
#  	# Reset count for new section.
#  	set counter 0
#  	set last_section $section_name
#  	append search_results "<h3>$section_name</h3>\n"
#      }
    
#      if { [ad_search_results_cutoff $counter $the_score $max_score] } {
#  	ns_db flush $db
#  	break
#      }

#      set one_line "<li>$the_score: <a href=\"$results_base_url$user_url_stub$the_key\">$one_line_description</a>\n"
#      if { $n_sections > 1 && $search_display_preference == "one_list" } {
#  	append search_results "$one_line <font size=-1>($section_name)</font>\n"
#      } else {
#  	append search_results $one_line
#      }

#      append search_results "(<a href=\"query-by-example?[export_url_vars sections table_name the_key]&subject=[ns_urlencode $one_line_description]\">more like this</a>)\n"
#  }

if { $search_display_preference != "by_section"} {
    # Generic Search
    with_catch errmsg {
	# to do: this catch should be moved around the db_foreach!
	set sql "select /*+ FIRST_ROWS */ score(10) as the_score, section_name, user_url_stub, the_key, one_line_description, sws.table_name
	from site_wide_index sws, table_acs_properties m
	where sws.table_name = m.table_name
	and contains(sws.datastore, '$subject_query and [join $about_clause " and "]', 10) > 0
	$sections_clause
	order by 1 desc"
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
    
    db_foreach weighted_search_select $sql {
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
		break
	    }
	}
	
	set one_line "<li>$the_score: <a href=\"$results_base_url$user_url_stub$the_key\">$one_line_description</a>\n"
	if { $n_sections > 1 && $search_display_preference == "one_list" } {
	    append search_results "$one_line <font size=-1>($section_name)</font>\n"
	} else {
	    append search_results $one_line
	}
	# LuisRodriguez@photo.net, June 2000
	# Make sure sections is first var in URL, otherwise MSIE 4.01 will turn "&sect"
	# into a multibyte char and thus mangle the URL
	append search_results "<font size=-1>(<a href=\"query-by-example?[export_url_vars sections table_name the_key]&subject=[ns_urlencode $one_line_description]\">more like this</a>)</font>\n"
    }

    if { [empty_string_p $search_results] } {
	set search_results "No hits found for your query."
    }
} else {
    # This is a by section wedge, so we can optimize this
    # Instead of going through the whole table row by row, we can constrain it
    # to each section, then perform multiple queries, which actually go faster
    # because we are only interested in the top few.

    set any_hits_p 0

    set search_results ""

    foreach s $sections {
	if { [string compare $s "bboard"] == 0} {
	    set sql_query "SELECT /*+ FIRST_ROWS */ SCORE(10) AS the_score, section_name, user_url_stub, the_key, one_line_description, sws.table_name
	    FROM site_wide_index sws, table_acs_properties m, bboard
	    WHERE sws.table_name='[DoubleApos $s]'
	    AND the_key=bboard.msg_id
	    AND sws.table_name = m.table_name
	    and contains(sws.datastore, '$subject_query and [join $about_clause " and "]', 10) > 0
	    AND bboard_user_can_view_topic_p($user_id,bboard.topic_id)= 't'
	    ORDER BY SCORE(10) DESC"
	} else {
	    set sql_query "SELECT /*+ FIRST_ROWS */ SCORE(10) AS the_score, section_name, user_url_stub, the_key, one_line_description, sws.table_name
	    FROM site_wide_index sws, table_acs_properties m
	    WHERE sws.table_name='[DoubleApos $s]'
	    AND sws.table_name = m.table_name
	    and contains(sws.datastore, '$subject_query and [join $about_clause " and "]', 10) > 0
	    ORDER BY SCORE(10) DESC"
	}
	with_catch errmsg {
	    # to do: this catch should also be moved to the db_foreach
	    set sql $sql_query
	} {
	    ad_return_error "Problem with interMedia" "There was a problem with interMedia 
	    while processing your query. This site wide search thing is still somewhat experimental,
	    so please bear with us while we work out the kinks. You may have better luck if you change
	    your query a little bit."
	    return
	}
	
	set counter 0
	set max_score 0

	db_foreach modified_search_select $sql {
	    incr counter
	    set any_hits_p 1

	    if { $counter == 1 } {
		set max_score $the_score
		append search_results "<h3>$section_name</h3>\n"
	    }
	    
	    if { [ad_search_results_cutoff $counter $the_score $max_score] } {
		# All done with current section
		break
	    } else {
		append search_results "<li>$the_score: <a href=\"$results_base_url$user_url_stub$the_key\">$one_line_description</a>\n"
		append search_results "<font size=-1>(<a href=\"query-by-example.tcl?[export_url_vars sections table_name the_key]&subject=[ns_urlencode $one_line_description]\">more like this</a>)</font>\n"
	    }
	}
    }
    if { !$any_hits_p } {
	append search_results "No hits found for your query."
    }

}

db_release_unused_handles

set page_content "[ad_header "Search Results"]

<h2>Search Results</h2>

[ad_context_bar_ws_or_index [list "index.tcl" "Search"] "Results"]

<hr>

Themes searched for: [join $themes ", "]

<ul>
$search_results
</ul>

[ad_footer]
"

doc_return  200 "text/html" $page_content
