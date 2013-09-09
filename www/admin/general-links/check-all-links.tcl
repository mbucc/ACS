# File: /admin/general-links/check-all-links.tcl

ad_page_contract {
    Checks all links for live/dead status and meta tags
    <code>ns_write</code> is used here because of the <code>ns_httpget</code> calls needed for link checking.

    @author Tzu-Mainn Chen (tzumainn@arsdigita.com)
    @creation-date 2/01/2000
    @cvs-id check-all-links.tcl,v 3.1.6.4 2000/07/21 03:57:21 ron Exp
} {
}

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

set return_url "check-all-links"


set link_info_list [db_list_of_lists select_link_info_list "select link_id, url from general_links order by url"]

foreach link_info $link_info_list {

    set link_id [lindex $link_info 0]
    set url [lindex $link_info 1]

    set check_p [ad_general_link_check $link_id]

    if { $check_p == 1 } {
	ns_write "<li><a href=\"$url\">$url</a> is <b>live</b>"
	
    } else {
	set last_live_date [db_string select_last_live_date {select last_live_date from general_links where link_id = :link_id} -default "N/A"]

	ns_write "
	<li><a href=\"$url\">$url</a> is <b>unreachable</b> - $check_p
	<br>Last Live Date: <b>$last_live_date</b>
	"
    }
    ns_write " - <a href=\"edit-link?[export_url_vars link_id return_url]\"</a>edit link</a> | <a href=\"delete-link?[export_url_vars link_id return_url]\"</a>delete link</a><p>"
}

db_release_unused_handles

ns_write "
</ul>

[ad_footer]
"
