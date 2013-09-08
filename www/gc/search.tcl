# /www/gc/search.tcl

ad_page_contract {
    displays a list of classified ads in a particular domain that match a query string

    @author teadams@arsdigita.com
    @author philg@mit.edu
    @creation-date 1995
    @cvs-id search.tcl,v 3.4.2.4 2000/09/22 01:37:56 kevin Exp
} {
    domain_id:integer
    query_string
}


if [empty_string_p $query_string] {
    ad_return_complaint 1 "<li>Please enter a string to search for."
    return
}


db_1row gc_search_domain_info_get [gc_query_for_domain_info $domain_id]

append html "[gc_header "$full_noun Search Results"]

<h2>$full_noun Search Results</h2>

[ad_context_bar_ws_or_index [list "index.tcl" [gc_system_name]] [list "domain-top.tcl?[export_url_vars domain_id]" $full_noun] "Search Results"]

<hr>

Ads matching \"$query_string\":

<ul>
"

regsub -all {,+} [string trim [DoubleApos $query_string]] " " final_query_string

set sql { 
    select pseudo_contains (indexed_stuff, :final_query_string) as the_score, ccv.*
    from classified_context_view ccv
    where pseudo_contains (indexed_stuff, :final_query_string) > 0
    and domain_id = :domain_id
    and (sysdate <= expires or expires is null)
    order by the_score desc
}

set counter 0 

db_foreach gc_search_result_list $sql {    
    incr counter
    if { ![info exists max_score] } {
	# first iteration, this is the highest score
	set max_score $the_score
    }

    if {[ad_context_end_output_p $counter $the_score $max_score] == 1} {
	ns_db flush
	break
    }

    set display_string $one_line
    append html "<li>$the_score: <a href=\"view-one?classified_ad_id=$classified_ad_id\">$display_string</a>\n"
}

set user_id [ad_get_user_id]
ad_record_query_string $query_string "classifieds-$domain" $counter $user_id

if { $counter == 0 } {
    set search_items "ads"
    set url "search.tcl?domain_id=$domain_id"
    append html "[ad_context_no_results]
    <form method=POST action=search target=\"_top\">
    <input type=hidden name=domain_id value=\"$domain_id\">
    New Search:  <input type=text name=query_string size=40 value=\"$query_string\">
    </form>"
}

append html "</ul>
[gc_footer $maintainer_email]
"

doc_return  200 text/html $html

