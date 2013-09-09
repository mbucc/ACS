# /www/neighbor/search-ctx.tcl
ad_page_contract {
    Searches the neighbor-to-neighbor data.

    @author Philip Greenspun (philg@mit.edu)
    @creation-date 1 January 1996
    @cvs-id search-ctx.tcl,v 3.2.2.2 2000/09/22 01:38:56 kevin Exp
    @param query_string_p what to search for
    @param accumulate_p whether the results should be accumulated
    @param fuzzy_p whether the search should be fuzzy
} {
    query_string:notnull
    accumulate_p:optional
    fuzzy_p:optional
}

set page_content "[neighbor_header "Postings Matching \"$query_string\""]

<h2>Postings Matching \"$query_string\"</h2>

in <a href=\"index\">[neighbor_system_name]</a>

<hr>

<ul>

"

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

set sql_query "
    select score(10) as the_score, nton.*
      from neighbor_to_neighbor nton
     where contains (indexed_stuff, '${prefix}($query_string_for_ctx)', 10) > 0
  order by score(10) desc"

if {![catch {db_foreach select_search $sql_query {
    if { ![info exists max_score] } {
	# first iteration, this is the highest score
	set max_score $the_score
    }
    if { ($counter > 25) && ($the_score < [expr 0.3 * $max_score] ) } {
	# we've gotten more than 25 rows AND our relevance score
	# is down to 30% of what the maximally relevant row was
	ns_db flush $db
	break
    }
    if { ($counter > 50) && ($the_score < [expr 0.5 * $max_score] ) } {
	# take a tougher look
	ns_db flush $db
	break
    }
    if { ($counter > 100) && ($the_score < [expr 0.8 * $max_score] ) } {
	# take a tougher look yet
	ns_db flush $db
	break
    }
    if { $one_line == "" } {
	set anchor $about
    } else {
	set anchor "$about : $one_line"
    }
    append page_content "<li>$the_score: <a href=\"view-one?neighbor_to_neighbor_id=$neighbor_to_neighbor_id\">$anchor</a>\n"
} if_no_rows {
    if { ![info exists fuzzy_p] && ![info exists accumulate_p] } {
	# nothin' special requested, offer special options
	append page_content "<li>sorry, but no messages matched this query.
Your query words were fed to Oracle ConText with instructions that
they had to appear near each other.  This is a good way of achieving
high relevance for common queries such as \"Nikon zoom lens\".
<p>
There are two basic ways in which we can expand your search:
<ol>
<li><a href=\"search?accumulate_p=t&query_string=[ns_urlencode $query_string]\">drop the proximity requirement</a>
<li><a href=\"search?fuzzy_p=t&query_string=[ns_urlencode $query_string]\">expand the search words to related terms (fuzzy)</a>
</ol>
"

    } else {
	# user is already doing something special but still losing unfortunately
	append page_content "<li>sorry, but no messages matched this query\n"
    }
}   } errmsg]} {
    # now the error handling
    append page_content "There aren't any results because something about
your query string has made Oracle Context unhappy:
<pre>
$errmsg
</pre>
In general, ConText does not like special characters.  It does not like
to see common words such as \"AND\" or \"a\" or \"the\".  
I haven't completely figured this beast out.

Back up and try again!

</ul>
<hr>
</body>
</html>"

    return

}


append page_content "</ul>

[neighbor_footer]"


db_release_unused_handles
doc_return 200 text/html $page_content