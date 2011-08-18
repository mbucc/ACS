# $Id: search.tcl,v 3.1 2000/03/10 23:58:32 curtisg Exp $
#
# /gc/search.tcl
#
# by teadams@arsdigita.com and philg@mit.edu
# ported from ancient (1995) crud
#
# displays a list of classified ads in a particular domain that match a query string
#

set_the_usual_form_variables

# domain_id, query_string

set db [gc_db_gethandle]


set selection [ns_db 1row $db [gc_query_for_domain_info $domain_id]]
set_variables_after_query

append html "[gc_header "$full_noun Search Results"]

<h2>$full_noun Search Results</h2>

[ad_context_bar_ws_or_index [list "index.tcl" [gc_system_name]] [list "domain-top.tcl?[export_url_vars domain_id]" $full_noun] "Search Results"]

<hr>

Ads matching \"$query_string\":

<ul>
"

regsub -all {,+} [string trim $QQquery_string] " " final_query_string

if [catch {set selection [ns_db select $db "select pseudo_contains(indexed_stuff, '$final_query_string') as the_score, ccv.*
from classified_context_view ccv
where pseudo_contains (indexed_stuff, '$final_query_string') > 0
and domain_id=$domain_id
and (sysdate <= expires or expires is null)
order by the_score desc"]} errmsg] {


    ad_return_error "Error in your search" "We couldn't complete your search. Here is what the database returned:
<p>
<blockquote>
<pre>
$errmsg
</pre>
</blockquote>
"
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

    if {[ad_context_end_output_p $counter $the_score $max_score] == 1} {
	ns_db flush $db
	break
    }

    set display_string $one_line
    append html "<li>$the_score: <a href=\"view-one.tcl?classified_ad_id=$classified_ad_id\">$display_string</a>\n"
}

    set user_id [ad_get_user_id]
    ad_record_query_string $query_string $db "classifieds-$domain" $counter $user_id

if { $counter == 0 } {
    set search_items "ads"
    set url "search.tcl?domain_id=$domain_id"
    append html "[ad_context_no_results]
    <form method=POST action=search.tcl target=\"_top\">
    <input type=hidden name=domain_id value=\"$domain_id\">
    New Search:  <input type=text name=query_string size=40 value=\"$query_string\">
    </form>"
}


append html "</ul>

[gc_footer $maintainer_email]
"

ns_return 200 text/html $html
