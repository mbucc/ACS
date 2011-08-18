# $Id: poll-results.tcl,v 3.0 2000/02/06 03:52:38 ron Exp $
# poll-results.tcl -- see the results of a poll

set_form_variables
# expects poll_id

validate_integer "poll_id" $poll_id
set info [util_memoize "poll_info_internal $poll_id"]

set poll_name [lindex $info 0]
set poll_description [lindex $info 1]

set db [ns_db gethandle]



set selection [ns_db select $db "
select pc.label, count(puc.choice_id) as n_votes
from poll_choices pc, poll_user_choices puc
where pc.poll_id = $poll_id
and pc.choice_id = puc.choice_id(+)
group by pc.label
order by n_votes desc"]



set total_count 0

# rather than make Oracle do the percentage calculation,
# we sum up the total_count and do the calcs ourselves.
# otherwise we'd have to do a seperate count(*), which would suck.

set intermediate_values [list]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    lappend intermediate_values [list $n_votes $label]
    incr total_count $n_votes
}

ns_db releasehandle $db

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
set context_bar [ad_context_bar_ws_or_index [list "/poll" "Polls"] [list "/poll/one-poll.tcl?[export_url_vars poll_id]" "One Poll"] "Results" ]

ad_return_template

