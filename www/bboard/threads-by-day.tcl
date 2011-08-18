# $Id: threads-by-day.tcl,v 3.0 2000/02/06 03:34:46 ron Exp $
# threads-by-date.tcl
# 
# shows number of threads in a forum initiated on a particular day,
# either all or limit to last 60 days
#
# by philg@mit.edu on June 26, 1999

set_the_usual_form_variables

# topic required, all_p is optional

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}


if { [bboard_get_topic_info] == -1 } {
    return
}

ReturnHeaders

ns_write "[bboard_header "$topic new threads by day"]

<h2>New Threads by Day</h2>

[ad_context_bar_ws_or_index [list "index.tcl" [bboard_system_name]] [list [bboard_raw_backlink $topic_id $topic $presentation_type 0] $topic] "Threads by Day"]

<hr>

Forum:  $topic

<ul>
"

set selection [ns_db select $db "select trunc(posting_time) as kickoff_date, count(*) as n_msgs
from bboard
where topic_id = $topic_id
and refers_to is null
group by trunc(posting_time)
order by 1 desc"]

set n_rows 0
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    incr n_rows
    if { ![info exists all_p] || !$all_p } {
	# we might have to cut off after 60 days
	if { $n_rows > 60 } {
	    append items "<p>
...
<p>
(<a href=\"threads-by-day.tcl?all_p=1&[export_url_vars topic]\">list entire history</a>)
"
            ns_db flush $db
            break
        } 
    }
    append items "<li>[util_AnsiDatetoPrettyDate $kickoff_date]:  <a href=\"threads-one-day.tcl?[export_url_vars topic topic_id kickoff_date]\">$n_msgs</a>\n"
}

if { $n_rows == 0 } {
    ns_write "there haven't been any postings to this forum (or all have been deleted by the moderators)"
} else {
    ns_write $items
}

ns_write "
</ul>

These counts do not reflect threads that were deleted by the forum
moderator(s).

[bboard_footer]
"
