# $Id: by-word-aggregate.tcl,v 3.0 2000/02/06 03:28:15 ron Exp $
set_the_usual_form_variables 0 

# minimum (optional)

if { ![info exists minimum] || [empty_string_p $minimum] } {
    set minimum 10 
}

ReturnHeaders

ns_write "[ad_admin_header "User Searches - word summary"]

<h2>User Searches - word summary</h2>

[ad_admin_context_bar [list "index.tcl" "User Searches"] "Summary by Word"]

<hr>

Query strings we've seen a minimum of $minimum times:

<ul>
"

set db [ns_db gethandle]

set selection [ns_db select $db "select query_string, count(query_string) as num_searches  from query_strings 
group by query_string
having count(query_string) >= $minimum
order by count(query_string) desc"]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    ns_write "<li><a href=\"by-word.tcl?query_string=[ns_urlencode $query_string]\">$query_string: $num_searches</a>"
}

ns_write "</ul>
[ad_admin_footer]
"
