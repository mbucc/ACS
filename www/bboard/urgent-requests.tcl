# $Id: urgent-requests.tcl,v 3.0 2000/02/06 03:34:53 ron Exp $
set_form_variables 0

if {![info exists skip_first]} {
  set skip_first 0
}

# archived_p

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}

if {[info exist archived_p] && $archived_p == "t"} {
    set title "Archived Urgent Requests"
} else {
    set title "Urgent Requests"
    set archived_p "f"
}

set user_id [ad_verify_and_get_user_id]

ReturnHeaders

ns_write "[bboard_header $title]

<h2>$title</h2>

[ad_context_bar_ws $title]

<hr>
[ad_decorate_side]

"

# let's do the urgent messages first, if necessary 

    set urgent_items [bboard_urgent_message_items $db $archived_p 3 50000 $skip_first]
    if ![empty_string_p $urgent_items] {
	ns_write "<ul>$urgent_items</ul>\n"
    }

ns_write "

<br clear=right>
<p>
[bboard_footer]
"
