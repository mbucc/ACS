# File: /admin/general-links/check-one-link.tcl
# Date: 2/01/2000
# Author: tzumainn@arsdigita.com 
#
# Purpose: 
# Checks one link for live/dead status and meta tags
#
# $Id: check-one-link.tcl,v 3.0 2000/02/06 03:23:35 ron Exp $
#--------------------------------------------------------

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set admin_id [ad_maybe_redirect_for_registration]

ad_page_variables {link_id}

ad_return_top_of_page "[ad_header "Check One Link" ]

<h2>Check One Link</h2>

[ad_admin_context_bar [list "" "General Links"] "Check One Link"]

<hr>
"

set db [ns_db gethandle]

set url [database_to_tcl_string $db "select url from general_links where link_id = $link_id"]

set check_p [ad_general_link_check $db $link_id]

if { $check_p == 1 } {
    set link_status "<a href=\"$url\">$url</a> is <b>live</b>"
} else {
    set last_live_date [database_to_tcl_string_or_null $db "select last_live_date from general_links where link_id = $link_id"]
    if [empty_string_p $last_live_date] {
	set last_live_date "N/A"
    }

    set link_status "
    <a href=\"$url\">$url</a> is <b>unreachable</b> - $check_p
    <br>Last Live Date: $last_live_date"
}

ns_db releasehandle $db

ns_write "
<ul>
<li> $link_status
</ul>

[ad_footer]
"
