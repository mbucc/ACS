# /www/bboard/threads-by-day.tcl

ad_page_contract {
    shows number of threads in a forum initiated on a particular day,
    either all or limit to last 60 days

    @author philg@mit.edu
    @creation-date 26 June 1999
    @cvs-id threads-by-day.tcl,v 3.2.2.5 2000/09/22 01:36:55 kevin Exp
} {
    topic:notnull
    {all_p 0}
}

# -----------------------------------------------------------------------------

if { [bboard_get_topic_info] == -1 } {
    return
}

append page_content "[bboard_header "$topic new threads by day"]

<h2>New Threads by Day</h2>

[ad_context_bar_ws_or_index [list "index.tcl" [bboard_system_name]] [list [bboard_raw_backlink $topic_id $topic $presentation_type 0] $topic] "Threads by Day"]

<hr>

Forum:  $topic

<ul>
"

set n_rows 0

db_foreach postings "
select trunc(posting_time) as kickoff_date, count(*) as n_msgs
from bboard
where topic_id = :topic_id
and refers_to is null
group by trunc(posting_time)
order by 1 desc" {

    incr n_rows
    if { !$all_p } {
	# we might have to cut off after 60 days
	if { $n_rows > 60 } {
	    append page_content "<p>
...
<p>
(<a href=\"threads-by-day?all_p=1&[export_url_vars topic]\">list entire history</a>)
"
            break
        } 
    }
    append page_content "<li>[util_AnsiDatetoPrettyDate $kickoff_date]:  <a href=\"threads-one-day?[export_url_vars topic topic_id kickoff_date]\">$n_msgs</a>\n"

} if_no_rows {
    append page_content "there haven't been any postings to this forum (or all have been deleted by the moderators)"
}

append page_content "
</ul>

These counts do not reflect threads that were deleted by the forum
moderator(s).

[bboard_footer]
"


doc_return  200 text/html $page_content