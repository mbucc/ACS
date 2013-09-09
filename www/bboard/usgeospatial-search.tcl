# /www/bboard/usgeospatial-search.tcl
ad_page_contract {
    @param query_string the string to search on
    @param topic the name of the bboard topic

    @author unknown
    @creation-date unknown
    @cvs-id usgeospatial-search.tcl,v 3.3.2.8 2000/09/22 01:36:58 kevin Exp
} {
    query_string:trim,notnull
    topic_id:integer
} 

# -----------------------------------------------------------------------------

if {[bboard_get_topic_info] == -1} {
    return
}

# we ask for all the top level messages

set page_content "[bboard_header "Search Results"]

<h2>Messages matching \"$query_string\"</h2>

in the <a href=\"usgeospatial?[export_url_vars topic topic_id]\">$topic forum</a> in <a href=\"[ad_pvt_home]\">[ad_system_name]</a>

<hr>

<ul>
"
# if the user put in commas, replace with spaces

regsub -all {,+} $query_string " " final_query_string

set counter 0 

db_foreach search_result "
select /*+ INDEX(bboard bboard_for_one_category) */ bboard_contains(email, first_names || last_name, one_line, message, :final_query_string) as the_score, 
       bboard.*, 
       states.usps_abbrev, 
       states.state_name, 
       counties.fips_county_name as county_name
from   bboard, 
       users, 
       states, 
       counties
where  bboard_contains(email, first_names || last_name, one_line, message, :final_query_string) > 0
and    bboard.usps_abbrev = states.usps_abbrev
and    bboard.fips_county_code = counties.fips_county_code(+)
and    bboard.user_id = users.user_id
and    topic_id = :topic_id
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
    
    if { [string first "." $sort_key] == -1 } {
	# there is no period in the sort key so this is the start of a thread
	set thread_start_msg_id $sort_key
    } else {
	# strip off the stuff before the period
	regexp {(.*)\..*} $sort_key match thread_start_msg_id
    }
    
    set display_string $one_line
    if { $subject_line_suffix == "name" } {
	append display_string "  ($name)"
    } elseif { $subject_line_suffix == "email" } {
	append display_string "  ($email)"
    }

    set about_string ""
    if ![empty_string_p $county_name] {
	set about_string "$county_name County, $usps_abbrev"
    } elseif ![empty_string_p $state_name] {
	set about_string $state_name
    }
    if ![empty_string_p $about_string] {
	set about_string "<font size=-1><br>&nbsp; &nbsp; &nbsp; &nbsp; (about $about_string)</font>"
    }

    append page_content "<li>$the_score: <a href=\"usgeospatial-fetch-msg?msg_id=$thread_start_msg_id\">$display_string</a> $about_string\n"

} if_no_rows {

    append page_content "<li>sorry, but no messages matched this query; remember that your query string should be space-separated words without plurals (since we're just doing simple stupid keyword matching)\n"
}

append page_content "
</ul>

<form method=GET action=usgeospatial-search target=\"_top\">
[export_form_vars topic topic_id]
New Search:  <input type=text name=query_string size=40 value=\"[philg_quote_double_quotes $query_string]\">
</form>

[bboard_footer]
"

doc_return  200 text/html $page_content







