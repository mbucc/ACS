# $Id: vote.tcl,v 3.0 2000/02/06 03:52:39 ron Exp $
# vote.tcl -- process a user's vote.

# markd@arsdigita.com and philg@mit.edu
# September 28, 1999

# this will record a vote UNLESS the user is registered and has
# already voted

set_the_usual_form_variables
#expects poll_id and choice_id

set header_image [ad_parameter IndexPageDecoration polls]
set context_bar [ad_context_bar_ws_or_index [list "/poll" "Polls"] [list "/poll/one-poll.tcl?[export_url_vars poll_id]" "One Poll"] "Confirm vote" ]


set user_id [ad_verify_and_get_user_id]

# sanity-check

# make sure they made a choice

if { ![info exists choice_id] || [empty_string_p $choice_id] } {
    # D'OH they didn't make a choice.
    set context_bar [ad_context_bar_ws_or_index [list "/poll" "Polls"] [list "/poll/one-poll.tcl?[export_url_vars poll_id]" "One Poll"] "Vote" ]
    ad_return_template novote
    return
}

# if it's a registration-only poll, make sure again that they
# don't vote again if they already have

set db [ns_db gethandle]

set selection [ns_db 0or1row $db "select require_registration_p, name as poll_name
from polls
where poll_id = $poll_id"]

if [empty_string_p $selection] {
    ad_return_error "Could not find poll" "Could not find poll $poll_id; perhaps it has been deleted by the site administrator"
    return
}

set_variables_after_query

if { $user_id != 0 } {
    set n_votes_already [database_to_tcl_string $db "select count(*) from poll_user_choices
where poll_id = $poll_id
and user_id = $user_id"]
    if { $n_votes_already > 0 } {
	ad_return_template already-voted
	return
    }
}

if { $user_id == 0 && $require_registration_p == "t" } {
    # this person is not logged in but is trying to vote in a registration 
    # required poll, the following procedure call will redirect the
    # person and also terminate thread execution
    ad_maybe_redirect_for_registration
}

set context_bar [ad_context_bar_ws_or_index [list "/poll" "Polls"] Thanks]

if { $user_id == 0 } {
    set user_id NULL
}

set insert_sql "insert into poll_user_choices
(poll_id, choice_id, user_id, choice_date, ip_address)
values
($poll_id, $choice_id, $user_id, sysdate, '[DoubleApos [ns_conn peeraddr]]')"


if [catch { ns_db dml $db $insert_sql } errmsg ] {
    ns_db releasehandle $db
    ad_return_template dberror
    return
}


ad_return_template

