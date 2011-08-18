# $Id: new-since-last-visit.tcl,v 3.1.2.1 2000/03/15 04:57:08 curtisg Exp $
set_the_usual_form_variables

# domain_id

set second_to_last_visit [ad_second_to_last_visit_ut]

if [empty_string_p $second_to_last_visit] {
    set second_to_last_visit [expr [ns_time] - 86400]
    set explanation "We didn't find a cookie header with your last visit info, so we're going to show you ads posted or modified within the last 24 hours."
} else {
    set explanation "These are ads posted or modified since your last visit, which we think was [ns_fmttime $second_to_last_visit "%x %X %Z"]"
}

set db [gc_db_gethandle]
set selection [ns_db 1row $db [gc_query_for_domain_info $domain_id]]
set_variables_after_query

append html "[gc_header "Ads Since Your Last Visit"]

<h2>Ads Since Your Last Visit</h2>

in the <a href=\"domain-top.tcl?domain_id=$domain_id\">$domain Classifieds</a>

<hr>

$explanation


<ul>

"

set selection [ns_db select $db "select classified_ad_id,one_line,posted
from classified_ads
where domain_id = $domain_id
and last_modified > to_date('[ns_fmttime $second_to_last_visit "%Y-%m-%d %H:%M:%S"]','YYYY-MM-DD HH24:MI:SS')
and (sysdate <= expires or expires is null)
order by classified_ad_id desc"]

set items ""
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    append items "<li><a href=\"view-one.tcl?classified_ad_id=$classified_ad_id\">$one_line</a> ([util_AnsiDatetoPrettyDate $posted])
"
}

if { ![empty_string_p $items] } {
    ns_db releasehandle $db
    append html "$items\n\n</ul>\n\n[gc_footer  $maintainer_email]\n"
    ns_return 200 text/html $html
    return
} 


# couldn't get any ads; let's solder on

append html "</ul>

<p> 

No new adds since [ns_fmttime $second_to_last_visit "%x %X %Z"].
Anyway, so that you're not disappointed, here are ads from the last 24
hours:

<ul>
"

set selection [ns_db select $db "select classified_ad_id,one_line,posted
from classified_ads
where domain_id = $domain_id
and last_modified > sysdate - 1
and (sysdate <= expires or expires is null)
order by classified_ad_id desc"]

set last_24_hours_items ""
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    append last_24_hours_items "<li><a href=\"view-one.tcl?classified_ad_id=$classified_ad_id\">$one_line</a>
    "
}

ns_db releasehandle $db

if { [empty_string_p $last_24_hours_items] } {
    append html "No ads have been placed in the last 24 hours."
} else {
    append html $last_24_hours_items
}

append html "</ul>
[gc_footer  $maintainer_email]
"

ns_return 200 text/html $html



