ad_page_contract {

    returns a list of all the deprecated procedures present 
    in server memory

    @cvs deprecated.tcl,v 1.1.2.4 2000/07/27 21:52:37 tnight Exp

    @author Todd Nightingale
    @date 2000-7-14

}

doc_set_property title "Deprecated Procedure Search"
doc_set_property navbar [list [list "" "API Browser"] "Deprecated Procedures"]
doc_set_property author "tnight@mit.edu"


set deprecated_matches ""

foreach proc [nsv_array names api_proc_doc] { 
    array set doc_elements [nsv_get api_proc_doc $proc]
 
    if {$doc_elements(deprecated_p) == 1} {
	lappend deprecated_matches [list $proc $doc_elements(positionals)]
    } 
}


if [empty_string_p $deprecated_matches] {
    doc_body_append "Sorry, no deprecated procedures found"
} else {
    doc_body_append "<h3>Deprecated Procedures:</h3><ul>"
    foreach proc $deprecated_matches {
	doc_body_append "<li><a href=proc-view?proc=[lindex $proc 0]>
	                        [lindex $proc 0]
                             </a><i>[lindex $proc 1]</i>"
    }
    doc_body_append "</ul>"
}


