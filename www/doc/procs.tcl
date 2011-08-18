# $Id: procs.tcl,v 3.0 2000/02/06 03:37:03 ron Exp $
# page that shows all the documented Tcl procs 
# in the system


# we assume that we get a list of lists, each one containing
# {proc_name filename} (i.e., a Tcl list in its own right)

proc procs_tcl_sort_by_first_element {l1 l2} {
    set first_comparison [string compare [lindex $l1 0] [lindex $l2 0]]
    if { $first_comparison != 0 } {
	return $first_comparison
    } else {
	return [string compare [lindex $l1 1] [lindex $l2 1]]
    }
}

proc procs_tcl_sort_by_second_element {l1 l2} {
    set first_comparison [string compare [lindex $l1 1] [lindex $l2 1]]
    if { $first_comparison != 0 } {
	return $first_comparison
    } else {
	return [string compare [lindex $l1 0] [lindex $l2 0]]
    }
}

set_form_variables 0

# maybe sort_by  (defaults to sorting by filename)

ReturnHeaders

ns_write "
[ad_header "Documented Procedures"]

<h2>Documented Procedures</h2>

in this installation of the ArsDigita Community System

<hr>

This page lists those procedures that the programmers have defined
using <code>proc_doc</code> (defined in
<a href=\"http://photo.net/wtr/thebook/utilities.txt\">/home/nsadmin/modules/tcl/utilities.tcl</a>).  

<p>

Note that any procedure beginning with <code>ns_</code> is an
AOLserver API call, documented at <a href=\"http://www.aolserver.com\">http://www.aolserver.com</a> (which also documents the basic Tcl language
built-in procedures).

"

set list_of_lists [list]

foreach proc_name [nsv_array names proc_doc] {
    lappend list_of_lists [list $proc_name [proc_source_file_full_path $proc_name]]
}

if { [info exists sort_by] && $sort_by == "name" } {
    set sorted_list [lsort -command procs_tcl_sort_by_first_element $list_of_lists]
    set headline "Procs by Name"
    set options "or sort by <a href=\"procs.tcl?sort_by=filename\">source file name</a>"
} else {
    # by filename
    set sorted_list [lsort -command procs_tcl_sort_by_second_element $list_of_lists]
    set headline "Procs by source filename"
    set options "or sort by <a href=\"procs.tcl?sort_by=name\">name</a>"
}

ns_write "

<form method=GET action=proc-search.tcl>
Search: <input type=text name=query_string size=40> (space-separated keywords)
</form>

<h3>$headline</h3>

$options

<ul>
"

set last_filename ""
foreach sublist $sorted_list {
    set proc_name [lindex $sublist 0]
    set filename [lindex $sublist 1]
    if { [info exists sort_by] && $sort_by == "name"} {
	ns_write "<li><a href=\"proc-one.tcl?proc_name=[ns_urlencode $proc_name]\">$proc_name</a> (defined in $filename)"
    } else {
	# we're doing this by filename
	if { $filename != $last_filename } {
	    ns_write "<h4>$filename</h4>\n"
	    set last_filename $filename
	}
	ns_write "<li><a href=\"proc-one.tcl?proc_name=[ns_urlencode $proc_name]\">$proc_name</a>\n"
    }
}

ns_write "
</ul>

[ad_admin_footer]
"
