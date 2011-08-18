# File: /admin/general-links/check-all-links.tcl
# Date: 2/01/2000
# Author: tzumainn@arsdigita.com 
#
# Purpose: 
#  Checks all links for live/dead status and meta tags
#
# $Id: check-all-links.tcl,v 3.0 2000/02/06 03:23:34 ron Exp $
#--------------------------------------------------------

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set admin_id [ad_maybe_redirect_for_registration]

ad_return_top_of_page "[ad_header "Check All Links" ]

<h2>Check All Links</h2>

[ad_admin_context_bar [list "" "General Links"] "Check All Links"]

<hr>

<ul>
"

set return_url "check-all-links.tcl"
set db [ns_db gethandle]

set link_info_list [database_to_tcl_list_list $db "select link_id, url from general_links order by url"]

foreach link_info $link_info_list {

    set link_id [lindex $link_info 0]
    set url [lindex $link_info 1]

    set check_p [ad_general_link_check $db $link_id]

    if { $check_p == 1 } {
	ns_write "<li><a href=\"$url\">$url</a> is <b>live</b>"
	
    } else {
	set last_live_date [database_to_tcl_string_or_null $db "select last_live_date from general_links where link_id = $link_id"]
	if [empty_string_p $last_live_date] {
	    set last_live_date "N/A"
	}

	ns_write "
	<li><a href=\"$url\">$url</a> is <b>unreachable</b> - $check_p
	<br>Last Live Date: <b>$last_live_date</b>
	"
    }
    ns_write " - <a href=\"edit-link.tcl?[export_url_vars link_id return_url]\"</a>edit link</a> | <a href=\"delete-link.tcl?[export_url_vars link_id return_url]\"</a>delete link</a><p>"
}

ns_db releasehandle $db

ns_write "
</ul>

[ad_footer]
"
