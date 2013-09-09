# packages/acs-core/api-doc/proc-browse.tcl

ad_page_contract {
    returns a list of all the procedures present 
    in server memory

    @cvs proc-browse.tcl,v 1.1.2.3 2000/08/15 22:03:29 ron Exp

    @author Todd Nightingale
    @date 2000-7-14

} {
    {type:optional Public}
    {sort_by:optional file} 
} 

doc_set_property title "$type Procedures"
doc_set_property navbar [list [list "" "API Browser"] "Browse Procedures"]
doc_set_property author "tnight@mit.edu"

set dimensional {
    {type "Type" "Public" {
	{All "All" ""}
	{Public "Public" ""}
	{Private "Private" ""}
	{Deprecated "Deprecated" ""}
}   }   
{sort_by "Sorted By" "file" {
    {file "File" ""}
    {name "Name" ""}
}   }   }

doc_body_append "
[ad_dimensional $dimensional]
<ul>" 

set matches ""
foreach proc [nsv_array names api_proc_doc] {
    array set doc_elements [nsv_get api_proc_doc $proc]

    if { $type == "All"} {
	lappend matches [list $proc $doc_elements(script)] 
    } elseif {$type == "Deprecated" && $doc_elements(deprecated_p)} {
	lappend matches [list $proc $doc_elements(script)] 
    } elseif {$type == "Private" && $doc_elements(private_p) } {
	lappend matches [list $proc $doc_elements(script)] 
    } elseif {$type == "Public" && $doc_elements(public_p) } {
	lappend matches [list $proc $doc_elements(script)] 
    } 
}


if { [string equal $sort_by "file"] } {
    set matches [lsort -command ad_sort_by_second_string_proc $matches]    
} else {
    set matches [lsort -command ad_sort_by_first_string_proc $matches]
}

set counter 0
set last_file ""
foreach sublist $matches {
    incr counter
    set proc [lindex $sublist 0]
    set file [lindex $sublist 1]
    set positionals [lindex $sublist 2]
    if { $sort_by == "name"} {
	doc_body_append "<li><a href=[api_proc_url $proc]>$proc</a> (defined in $file)"
    } else {
	# we're doing this by filename
	if { $file != $last_file } {
	    doc_body_append "</ul><b>$file</b><ul>\n"
	    set last_file $file
	}
	doc_body_append "<li><a href=[api_proc_url $proc]>$proc</a>\n"
    }
}

if {!$counter} {
    doc_body_append "Sorry, no procedures found"
}
doc_body_append "</ul>$counter Procedures Found"


