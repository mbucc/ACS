# poll-results.tcl,v 3.2.2.4 2000/07/21 04:03:17 ron Exp
# poll-results.tcl -- see the results of a poll

ad_page_contract {
    @param poll_id the ID of the poll
    @cvs-id poll-results.tcl,v 3.2.2.4 2000/07/21 04:03:17 ron Exp
} {
    poll_id:naturalnum,notnull
}

set info [util_memoize "poll_info_internal $poll_id"]

set poll_name [lindex $info 0]
set poll_description [lindex $info 1]

set intermediate_values [list]
set total_count 0
db_foreach poll_get_info "
select pc.label, count(puc.choice_id) as n_votes
from poll_choices pc, poll_user_choices puc
where pc.poll_id = :poll_id
and pc.choice_id = puc.choice_id(+)
group by pc.label
order by n_votes desc" {



# rather than make Oracle do the percentage calculation,
# we sum up the total_count and do the calcs ourselves.
# otherwise we'd have to do a seperate count(*), which would suck.


    lappend intermediate_values [list $n_votes $label]
    incr total_count $n_votes
}

db_release_unused_handles

set values [list]

if { $total_count > 0 } {
    
    foreach row $intermediate_values {
	set n_votes "[lindex $row 0].0"
	set label [lindex $row 1]
	
	# only display one digit after the decimal point
	set percent [format "%.1f" [expr $n_votes/$total_count * 100.0]]
	
	if { $n_votes == 1 } {
	    set vote_text "vote"
	} else {
	    set vote_text "votes"
	}
	
	lappend values [list $label "" $percent]
    }
}

set header_image [ad_parameter IndexPageDecoration polls]
set context_bar [ad_context_bar_ws_or_index [list "/poll" "Polls"] [list "/poll/one-poll?[export_url_vars poll_id]" "One Poll"] "Results" ]

ad_return_template


