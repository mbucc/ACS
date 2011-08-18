# $Id: company-search.tcl,v 3.0 2000/02/06 03:33:38 ron Exp $
set_the_usual_form_variables

# query_string

# poke around the company synonym table 

set db [ns_db gethandle]

# if { ![get_personalization_info "*"] } {
#     # we don't know who this person is
#     set prefer_text_only_p [score_get_user_graphics_default]
# }
set prefer_text_only_p t

ReturnHeaders

ns_write "[score_header_value "Search Results for: \"$query_string\""]\n"

if {$prefer_text_only_p == "t"} {
    ns_write "<h2>Search Results for: \"$query_string\"</h2>

in <a href=\"/\">[score_system_name]</a>

<hr>

<ul>
"
}

# reuse score_chem_name_match_score from the chemicals search, as it
# seems like a useful metric
set selection [ns_db select $db "SELECT distinct
  f.tri_id, f.facility, f.city, f.st, p.edf_parent,
  score_chem_name_match_score(upper(f.facility), upper('$QQquery_string')) as match_score
FROM 
  rel_edf_parent p, rel_search_fac f, bboard
WHERE
  f.tri_id = p.tri_id(+)
  and (upper(f.facility) like upper('%$QQquery_string%')
       or upper(p.edf_parent) like upper('%$QQquery_string%'))
  and f.tri_id = bboard.tri_id
ORDER BY
   score_chem_name_match_score(upper(f.facility), upper('$QQquery_string')),
   score_chem_name_match_score(upper(p.edf_parent), upper('$QQquery_string'))"]


set count 0
set last_match_score ""
set first_iteration_p 1
set tris_found [list]
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    incr count
    lappend tris_found $tri_id
    if $first_iteration_p {
	ns_write "<h4>Messages have been posted about the following facilities</h4>\n"
    }
    if { $last_match_score != $match_score && !$first_iteration_p } {
	ns_write "\n\n<P>\n\n"
    }
    ns_write "<li><a href=\"usgeospatial-one-facility.tcl?tri_id=$tri_id&topic=Pollution+in+Your+Community\">$facility</a> ($city, $st)"
    set last_match_score $match_score
    set first_iteration_p 0
}

if { $count == 0 } {
    ns_write "Sorry, no one has posted any messages about facilities matching your search.\n"
    set already_found_exclusion ""
} else {
    set already_found_exclusion "and f.tri_id not in ('[join $tris_found "','"]')"
}

# let's try searching for facilities period
set selection [ns_db select $db "SELECT distinct
  f.tri_id, f.facility, f.city, f.st, p.edf_parent,
  score_chem_name_match_score(upper(f.facility), upper('$QQquery_string')) as match_score
FROM 
  rel_edf_parent p, rel_search_fac f
WHERE
  f.tri_id = p.tri_id(+)
  $already_found_exclusion
  and (upper(f.facility) like upper('$QQquery_string%')
       or upper(f.facility) like upper('% $QQquery_string%')
       or upper(p.edf_parent) like upper('$QQquery_string%')
       or upper(p.edf_parent) like upper('% $QQquery_string%'))
ORDER BY
   score_chem_name_match_score(upper(f.facility), upper('$QQquery_string')),
   score_chem_name_match_score(upper(p.edf_parent), upper('$QQquery_string')),
   st, city"]
     while { [ns_db getrow $db $selection] } {
	 set_variables_after_query
	 append facility_matches "<li><a href=\"/env-releases/facility.tcl?tri_id=[ns_urlencode $tri_id]\">$facility</a> ($city, $st)\n"
     }
     if [info exists facility_matches] {
	 ns_write "<h4>Start a discussion on one of the following facilities</h4>
(go to the Take Action section of a facility report and join an on-line discussion)

<p>
$facility_matches"
     }

if {$prefer_text_only_p == "t"} {
    ns_write "</ul>[score_footer_value]"
}
