# one-poll.tcl

ad_page_contract {
    Display one poll.

    @param poll_id the ID of the poll
    
    @cvs-id one-poll.tcl,v 3.2.2.4 2000/07/21 04:03:17 ron Exp
} {
    poll_id:naturalnum,notnull
}


set header_image [ad_parameter IndexPageDecoration polls]
set context_bar [ ad_context_bar_ws_or_index [list "/poll" "Polls"] "One Poll"]

# throw an error if this isn't an integer

set info [util_memoize "poll_info_internal $poll_id"]

set poll_name [lindex $info 0]
set poll_description [lindex $info 1]
set start_date [lindex $info 2]
set end_date [lindex $info 3]
set require_registration_p [lindex $info 4]
set active_p [lindex $info 5]

set page_title $poll_name

if { $active_p == "f" } {
    ad_return_template not-active
    return
}

# if registration required, see if they've already voted and
# disallow.
# if registration isn't required, don't bother (why restrict
# registered users from stuffing the ballot box?)

set user_id [ad_verify_and_get_user_id]

if { $require_registration_p == "t" } {
   ad_maybe_redirect_for_registration
}

set form_html "
[export_form_vars poll_id]
"

# get a list with the labels and choice id's

set choices [util_memoize "poll_labels_internal $poll_id"]

ad_return_template



