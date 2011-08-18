# $Id: index.tcl,v 3.0 2000/02/06 03:52:36 ron Exp $
# index.tcl - main page of polls

# construct list of available polls

set db [ns_db gethandle]

set selection [ns_db select $db "
select poll_id, name, require_registration_p
  from polls
 where poll_is_active_p(start_date, end_date) = 't'
"]


set polls [list]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query

    lappend polls "<a href=\"one-poll.tcl?[export_url_vars poll_id]\">$name</a>"

    lappend polls $require_registration_p
}

ns_db releasehandle $db


set page_title "Polls"

set header_image [ad_parameter IndexPageDecoration polls]
set context_bar [ad_context_bar_ws_or_index "Polls"]

ad_return_template


