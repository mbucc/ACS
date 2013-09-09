# index.tcl

ad_page_contract {
    Construct list of available polls.

    @cvs-id index.tcl,v 3.2.2.4 2000/07/21 04:03:16 ron Exp
} {
}

set polls [list]
db_foreach  polls_get_list "
select poll_id, name, require_registration_p
  from polls
 where poll_is_active_p(start_date, end_date) = 't'
" {

    lappend polls "<a href=\"one-poll?[export_url_vars poll_id]\">$name</a>"

    lappend polls $require_registration_p
}

db_release_unused_handles

set page_title "Polls"

set header_image [ad_parameter IndexPageDecoration polls]
set context_bar [ad_context_bar_ws_or_index "Polls"]

ad_return_template

