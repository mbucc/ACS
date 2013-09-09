# /poll/vote.tcl

ad_page_contract {
    This will record a vote UNLESS the user is registered and has already voted

    @param poll_id the ID of the poll
    @param choice_id the ID of the choice
    
    @author Mark Dalrymple (markd@arsdigita.com)
    @author Philip Greenspun (philg@mit.edu)
    @creation-date 28 September 1999
    @cvs-id vote.tcl,v 3.2.2.7 2000/12/20 23:25:14 kevin Exp
} {
    poll_id:notnull,naturalnum
    choice_id:notnull,naturalnum
}

set header_image [ad_parameter IndexPageDecoration polls]
set context_bar [ad_context_bar_ws_or_index [list "/poll" "Polls"] [list "/poll/one-poll?[export_url_vars poll_id]" "One Poll"] "Confirm vote" ]


set user_id [ad_verify_and_get_user_id]

# if it's a registration-only poll, make sure again that they
# don't vote again if they already have



if { [db_0or1row poll_info "select require_registration_p, name as poll_name
from polls
where poll_id = :poll_id"] == 0 } {

    ad_return_error "Could not find poll" "Could not find poll $poll_id; perhaps it has been deleted by the site administrator"
    return
}



if { $user_id != 0 } {
    set n_votes_already [db_string select_n_votes "select count(*) from poll_user_choices
where poll_id = :poll_id
and user_id = :user_id"]
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
    set user_id [db_null]
}

set insert_sql "insert into poll_user_choices
(poll_id, choice_id, user_id, choice_date, ip_address)
values
(:poll_id, :choice_id, :user_id, sysdate, '[DoubleApos [ns_conn peeraddr]]')"


if [catch { db_dml insert_choice $insert_sql } errmsg ] {
    db_release_unused_handles
    ad_return_template dberror
    return
}


ad_return_template


