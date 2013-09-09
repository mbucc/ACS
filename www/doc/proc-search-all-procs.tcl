proc procs_tcl_sort_by_second_element_desc {l1 l2} {
    set first_comparison [string compare [lindex $l2 1] [lindex $l1 1]]
    if { $first_comparison != 0 } {
	return $first_comparison
    } else {
	return [string compare [lindex $l2 0] [lindex $l1 0]]
    }
}


ad_page_contract {
    this is for searching through all defined procedures, their args,
    and their bodies

    @param query_string
    @param exclude_body_p

    @author ?
    @creation-date ?
    @cvs-id proc-search-all-procs.tcl,v 3.2.2.3 2000/09/22 01:37:22 kevin Exp
} {
    query_string:notnull
    exclude_body_p:optional
}


if { ![info exists query_string] || [empty_string_p $query_string] } {
    ad_return_complaint 1 "<li>we need at least one word for which you're searching."
    return
}

set page_content "
[ad_header "Procedures matching \"$query_string\""]

<h2>Matches for \"$query_string\"</h2>

among all the procedures (not just the documented ones) in this
installation of the ACS

<hr>

<ul>
"

# each elt is [list $proc_name $score $real_proc_p]
set results [list]

set real_procedures [info procs]

foreach proc_name [info commands] {
    set string_to_search ""
    append string_to_search $proc_name 
    if { [lsearch -exact $real_procedures $proc_name] != -1 } {
	# this is a real procedure, not a command or C function
	set real_proc_p 1
	append string_to_search [info args $proc_name]
	if { ![info exists exclude_body_p] || $exclude_body_p == 0 } {
	    append string_to_search [info body $proc_name]
	}
    } else {
	set real_proc_p 0
    }
    set score [philg_keywords_score $query_string $string_to_search]
    if { $score > 0 } {
	lappend results [list $proc_name $score $real_proc_p]
    }
}

set sorted_results [lsort -command procs_tcl_sort_by_second_element_desc $results]

if { [llength $sorted_results] > 0 } {
    if { [llength $sorted_results] > 15 && (![info exists exclude_body_p] || $exclude_body_p == 0) } {
	append page_content "<li><a href=\"proc-search-all-procs?exclude_body_p=1&[export_url_vars query_string]\">query again for \"$query_string\" but don't search through procedure bodies</a>\n<p>\n"
    }
    foreach sublist $sorted_results {
	set proc_name [lindex $sublist 0]
	set score [lindex $sublist 1]
	set real_proc_p [lindex $sublist 2]
	if $real_proc_p {
	append page_content "<li>$score: <b><a href=\"proc-one?proc_name=[ns_urlencode $proc_name]\">$proc_name</a></b>  <i>[info args $proc_name]</i>\n"
	} else {
	    append page_content "<li>$score: $proc_name (most likely documented at <a href=\"http://www.aolserver.com/server/docs/2.3/html/tcldev.htm\">www.aolserver.com</a>)\n"
	}
    }
} else {
    append page_content "no results found"
}

append page_content "

</ul>

[ad_admin_footer]
"


#db_release_unused_handles
doc_return  200 text/html $page_content



