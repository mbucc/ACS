# File: /admin/general-links/check-one-link.tcl

ad_page_contract {
    Checks one link for live/dead status and meta tags.
    Note the ns_write method is used here because ns_httpget and doc_return  may timeout the browser when used together.

    @param link_id The ID of the link to check

    @author Tzu-Mainn Chen (tzumainn@arsdigita.com)
    @creation-date 2/01/2000
    @cvs-id check-one-link.tcl,v 3.0.12.6 2000/09/22 01:35:24 kevin Exp
} {
    link_id:notnull,naturalnum
}

#--------------------------------------------------------

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set admin_id [ad_maybe_redirect_for_registration]

ad_return_top_of_page "[ad_header "Check One Link" ]

<h2>Check One Link</h2>

[ad_admin_context_bar [list "" "General Links"] "Check One Link"]

<hr>
"

set url [db_string select_url {select url from general_links where link_id = :link_id}]

set check_p [ad_general_link_check $link_id]

if { $check_p == 1 } {
    set link_status "<a href=\"$url\">$url</a> is <b>live</b>"
} else {
    set last_live_date [db_string -default "" select_last_live_date {select last_live_date from general_links where link_id = :link_id}]
    if [empty_string_p $last_live_date] {
	set last_live_date "N/A"
    }

    set link_status "
    <a href=\"$url\">$url</a> is <b>unreachable</b> - $check_p
    <br>Last Live Date: $last_live_date"
}

db_release_unused_handles

ns_write "
<ul>
<li> $link_status
</ul>

[ad_footer]
"
