# /tcl/ad-fulltext-search.tcl

ad_library {

    Site wide search private tcl
    definitions having to do with full text searches
    (typically carried out with Oracle Context (not free) 
    or PLS from http://www.pls.com (free))

    @creation-date ?
    @author ?
    @cvs-id ad-fulltext-search.tcl,v 3.1.2.2 2000/07/13 17:57:19 bquinn Exp
}


ad_proc ad_return_context_error {errmsg} {standard error message for bad context searches} {

    return "There aren't any results because something about
            your query string has made Oracle Context unhappy:
            <pre>
            $errmsg
            </pre>
            In general, ConText does not like special characters.  It does not like
            to see common words such as \"AND\" or \"a\" or \"the\".  
            I haven't completely figured this beast out.

            Back up and try again!"
}

# CONTEXT PROCEDURES

ad_proc ad_context_query_string {} {
    Standard formation of the context query -- assumes that the variable query_string exists
} {
    uplevel {
	regsub -all {@} [string trim $query_string] {\@} query_string
	regsub -all { +} [string trim $query_string] "," query_string_for_ctx
	
	# we've separated the words with commas (sometimes more than one if the
	# user typed multiple spaces)
	
	if { [info exists accumulate_p] && $accumulate_p == "t" } {
	    # we bash down multiple commas to one comma (the 
	    # accumulate operator, score = sum of word appearance)
	    regsub -all {,+} $query_string_for_ctx "," query_string_for_ctx
	} else {
	    # this is the default, let's try the NEAR operator, tends
	    # to result in tighter more relevant results
	    regsub -all {,+} $query_string_for_ctx ";" query_string_for_ctx
	}
	
	set prefix {$}
	if { [info exists fuzzy_p] && $fuzzy_p == "t" } {
	    append prefix {?}
	}
    }
    return
}



ad_proc ad_context_no_results {} {
    standard context message for searches with no results 
    if the user can expand the search, this will return
    the appropriate string
    you must set the variable search_items before this is called
    user output --- ie "messages", "classified ads"
    also assumes this follows the standard search pattern
} {
    uplevel {
	
	if ![info exists url] {
	    set url [ns_conn url]?
	}

	if { ![info exists fuzzy_p] && ![info exists accumulate_p] } {
	    # nothin' special requested, offer special options
	    return "<li>sorry, but we found no matching $search_items for  this request.
Your query words were fed to Oracle ConText with instructions that
they had to appear near each other.  This is a good way of achieving
high relevance for common queries such as \"Nikon zoom lens\".
<p>
There are two basic ways in which we can expand your search:
<ol>
<li><a href=\"$url&accumulate_p=t&query_string=[ns_urlencode $query_string]\">drop the proximity requirement</a>
<li><a href=\"$url&fuzzy_p=t&query_string=[ns_urlencode $query_string]\">expand the search words to related terms (fuzzy)</a>
</ol>
"
        } else {
	    # user is already doing something special but still losing unfortunately
	    return "Sorry, but no matching $search_items for this query\n"
	}	
    }
    return 
}

ad_proc ad_context_end_output_p {counter the_score max_score} {
    determines if the search results are irrelevent and
    if the output should be aborted
} {

    if { ($counter > 25) && ($the_score < [expr 0.3 * $max_score] ) } {
	# we've gotten more than 25 rows AND our relevance score
	# is down to 30% of what the maximally relevant row was
	return 1
	break
    }
    if { ($counter > 50) && ($the_score < [expr 0.5 * $max_score] ) } {
	# take a tougher look
	return 1
	break
    }
    if { ($counter > 100) && ($the_score < [expr 0.8 * $max_score] ) } {
	# take a tougher look yet
	return 1
	break
    }
    return 0
}

