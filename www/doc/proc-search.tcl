# $Id: proc-search.tcl,v 3.2 2000/03/10 21:12:17 lars Exp $

proc procs_tcl_sort_by_second_element {l1 l2} {
    set first_comparison [string compare [lindex $l1 1] [lindex $l2 1]]
    if { $first_comparison != 0 } {
	return $first_comparison
    } else {
	return [string compare [lindex $l1 0] [lindex $l2 0]]
    }
}

proc procs_tcl_sort_by_second_element_desc {l1 l2} {
    set first_comparison [string compare [lindex $l2 1] [lindex $l1 1]]
    if { $first_comparison != 0 } {
	return $first_comparison
    } else {
	return [string compare [lindex $l2 0] [lindex $l1 0]]
    }
}

set_form_variables 0

# query_string, maybe exclude_body_p

if { ![info exists query_string] || [empty_string_p $query_string] } {
    ad_return_complaint 1 "<li>we need at least one word for which you're searching."
    return
}

ReturnHeaders

ns_write "
[ad_header "Procedures matching \"$query_string\""]

<h2>Matches for \"$query_string\"</h2>

among <a href=\"procs.tcl\">the documented procedures</a> in this
installation of the ACS


<hr>

<ul>
"

set list_of_lists [list]


foreach proc_name [nsv_array names proc_doc] {
    lappend list_of_lists [list $proc_name [proc_source_file_full_path $proc_name]]
}

# sort them by file name for stability of results
# (i.e., stuff that is together in a file will tend to get printed out
# together)

set sorted_list [lsort -command procs_tcl_sort_by_second_element $list_of_lists]

# each elt is [list $proc_name $score]
set results [list]

foreach sublist $sorted_list {
    set proc_name [lindex $sublist 0]
    set filename [lindex $sublist 1]
    set string_to_search ""
    append string_to_search $proc_name [info args $proc_name] [nsv_get proc_doc $proc_name]
    if { ![info exists exclude_body_p] || $exclude_body_p == 0 } {
	append string_to_search [info body $proc_name]
    }
    set score [philg_keywords_score $query_string $string_to_search]
    if { $score > 0 } {
	lappend results [list $proc_name $score]
    }
}

set sorted_results [lsort -command procs_tcl_sort_by_second_element_desc $results]

if { [llength $sorted_results] > 0 } {
    if { [llength $sorted_results] > 15 && (![info exists exclude_body_p] || $exclude_body_p == 0) } {
	ns_write "<li><a href=\"proc-search.tcl?exclude_body_p=1&[export_url_vars query_string]\">query again for \"$query_string\" but don't search through procedure bodies</a>\n<p>\n"
    }
    foreach sublist $sorted_results {
	set proc_name [lindex $sublist 0]
	set score [lindex $sublist 1]
	ns_write  "<li>$score: <b><a href=\"proc-one.tcl?proc_name=[ns_urlencode $proc_name]\">$proc_name</a></b> <i>[info args $proc_name]</i>\n"
    }
} else {
    ns_write "no results found"
}

ns_write "

<P>

<li><a href=\"proc-search-all-procs.tcl?[export_url_vars query_string]\">query again for \"$query_string\" but this time search through all defined procedures, even system and undocumented procedures</a>\n<p>\n


</ul>

[ad_admin_footer]
"
