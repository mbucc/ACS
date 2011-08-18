# $Id: usgeospatial-search.tcl,v 3.1 2000/02/23 01:49:40 bdolicki Exp $
set_the_usual_form_variables

# query_string, topic

if { ![info exists query_string] || $query_string == "" } {
    # probably using MSIE
    ns_return 200 text/html "[bboard_header "Missing Query"]

<h2>Missing Query</h2>

<hr>

Either you didn't type a query string or you're using a Web browser
like Microsoft Internet Explorer 3.x (which neglects to pass user
input up the server).

[bboard_footer]
"
    return
}

set db [bboard_db_gethandle]

if { $db == "" } {
    bboard_return_error_page
    return
}


if {[bboard_get_topic_info] == -1} {
    return
}


# we ask for all the top level messages

ReturnHeaders

ns_write "[bboard_header "Search Results"]

<h2>Messages matching \"$query_string\"</h2>

in the <a href=\"usgeospatial.tcl?[export_url_vars topic topic_id]\">$topic forum</a> in <a href=\"[ad_pvt_home]\">[ad_system_name]</a>

<hr>

<ul>
"
# if the user put in commas, replace with spaces

regsub -all {,+} [string trim $QQquery_string] " " final_query_string

if [catch {set selection [ns_db select $db "select /*+ INDEX(bboard bboard_for_one_category) */ bboard_contains(email, first_names || last_name, one_line, message,'$final_query_string') as the_score, bboard.*, rel_search_st.state as usps_abbrev, rel_search_st.state_name, rel_search_co.fips_county_name as county_name, facility
from bboard, users, rel_search_st, rel_search_co, rel_search_fac
where bboard_contains(email, first_names || last_name, one_line, message,'$final_query_string') > 0
and bboard.usps_abbrev = rel_search_st.state
and bboard.fips_county_code = rel_search_co.fips_county_code(+)
and bboard.tri_id = rel_search_fac.tri_id(+)
and bboard.user_id = users.user_id
and topic_id = $topic_id
order by 1 desc"]} errmsg] {
    ns_write "Ouch!  Our query made Oracle unhappy:
<pre>
$errmsg
</pre>
</ul>
[bboard_footer]"
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
    if { ![empty_string_p $facility] } {
	set about_string "$facility in $county_name County, $usps_abbrev"
    } elseif ![empty_string_p $county_name] {
	set about_string "$county_name County, $usps_abbrev"
    } elseif ![empty_string_p $state_name] {
	set about_string $state_name
    }
    if ![empty_string_p $about_string] {
	set about_string "<font size=-1><br>&nbsp; &nbsp; &nbsp; &nbsp; (about $about_string)</font>"
    }
    ns_write "<li>$the_score: <a href=\"usgeospatial-fetch-msg.tcl?msg_id=$thread_start_msg_id\">$display_string</a> $about_string\n"
}

if { $counter == 0 } {
    ns_write "<li>sorry, but no messages matched this query; remember that your query string should be space-separated words without plurals (since we're just doing simple stupid keyword matching)\n"
}

ns_write "
</ul>

<form method=GET action=usgeospatial-search.tcl target=\"_top\">
[export_form_vars topic topic_id]
New Search:  <input type=text name=query_string size=40 value=\"[philg_quote_double_quotes $query_string]\">
</form>

[bboard_footer]
"

