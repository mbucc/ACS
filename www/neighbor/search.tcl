# search.tcl
ad_page_contract {
    Searches the postings.

    @author Philip Greenspun (philg@mit.edu)
    @creation-date 1 January 1996
    @cvs-id search.tcl,v 3.2.2.2 2000/09/22 01:38:56 kevin Exp
    @param query_string the string to search for
} {
    query_string:nohtml,trim
}

append doc_body "[neighbor_header "Postings Matching \"$query_string\""]

<h2>Postings Matching \"$query_string\"</h2>

in <a href=\"index\">[neighbor_system_name]</a>

<hr>

<ul>

"

# if the user put in commas, replace with spaces

regsub -all {,+} $query_string " " final_query_string

set counter 0 

if [catch {db_foreach results "select pseudo_contains(dbms_lob.substr(body,3000) || title || about, :final_query_string) as the_score, 
                                       nton.about, nton.title, nton.neighbor_to_neighbor_id
                                  from neighbor_to_neighbor nton
                                 where pseudo_contains (dbms_lob.substr(body,3000) || title || about, :final_query_string) > 0
                                 order by 1 desc" {
    incr counter
    if { ![info exists max_score] } {
	# first iteration, this is the highest score
	set max_score $the_score
    }
    if { ($counter > 25) && ($the_score < [expr 0.3 * $max_score] ) } {
	# we've gotten more than 25 rows AND our relevance score
	# is down to 30% of what the maximally relevant row was
	break
    }
    if { ($counter > 50) && ($the_score < [expr 0.5 * $max_score] ) } {
	# take a tougher look
	break
    }
    if { ($counter > 100) && ($the_score < [expr 0.8 * $max_score] ) } {
	# take a tougher look yet
	break
    }
    if { $title == "" } {
	set anchor $about
    } else {
	set anchor "$about : $title"
    }
    append doc_body "<li>$the_score: <a href=\"view-one?neighbor_to_neighbor_id=$neighbor_to_neighbor_id\">$anchor</a>\n"
    } if_no_rows {
	append doc_body "<li>sorry, but no postings matched this query\n"
    } } errmsg] {
	ad_return_error "Invalid Query" "There aren't any results because something about
your query string has made Oracle unhappy:
<pre>
$errmsg
</pre>

Back up and try again!

</ul>
<hr>
</body>
</html>"

return
}


append doc_body "</ul>

[neighbor_footer]"

db_release_unused_handles
doc_return 200 text/html $doc_body