# $Id: search.tcl,v 3.0 2000/02/06 03:50:01 ron Exp $
set_the_usual_form_variables

# query_string
   
ReturnHeaders

ns_write "[neighbor_header "Postings Matching \"$query_string\""]

<h2>Postings Matching \"$query_string\"</h2>

in <a href=\"index.tcl\">[neighbor_system_name]</a>

<hr>

<ul>

"

set db [neighbor_db_gethandle]

# if the user put in commas, replace with spaces

regsub -all {,+} [string trim $QQquery_string] " " final_query_string

if [catch {set selection [ns_db select $db "select pseudo_contains(dbms_lob.substr(body,3000) || title || about, '$final_query_string') as the_score, nton.*
from neighbor_to_neighbor nton
where pseudo_contains (dbms_lob.substr(body,3000) || title || about, '$final_query_string') > 0
order by 1 desc"]} errmsg] {

    ns_write "There aren't any results because something about
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


set counter 0 

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    incr counter
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
    if { $title == "" } {
	set anchor $about
    } else {
	set anchor "$about : $title"
    }
    ns_write "<li>$the_score: <a href=\"view-one.tcl?neighbor_to_neighbor_id=$neighbor_to_neighbor_id\">$anchor</a>\n"
}

if { $counter == 0 } {
    ns_write "<li>sorry, but no postings matched this query\n"
}


ns_write "</ul>

[neighbor_footer]"
