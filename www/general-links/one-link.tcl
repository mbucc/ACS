# File: /general-links/one-link.tcl
# Date: 2/01/2000
# Author: tzumainn@arsdigita.com 
#
# Purpose: 
#  Displays more link information
#
# $Id: one-link.tcl,v 3.0 2000/02/06 03:44:29 ron Exp $
#--------------------------------------------------------

ad_page_variables {link_id {return_title "General Links"} {return_url "index.tcl"}}

set db [ns_db gethandle]

set selection [ns_db 0or1row $db "select link_id, creation_time, url, link_title, link_description
from general_links gl
where link_id=$link_id
"]

page_validation {
    if {[empty_string_p $selection]} {
	error "Link $link_id does not exist."
    }
}

set_variables_after_query

if {[ad_parameter ClickthroughP general-links] == 1} {
    set exact_link "/ct/ad_link_${link_id}?send_to=$url"
} else {
    set exact_link "$url"
}

set link_html "<ul>
<li><a href=\"$exact_link\"><b>$link_title</b></a> - [ad_general_link_format_rating_result $db $link_id]
<p>$link_description
<p>Posted on [util_AnsiDatetoPrettyDate $creation_time]
<p>
[ad_general_link_format_rating $db $link_id "link-rate.tcl"]
<p>
</ul>"

set comments [ad_general_comments_list $db $link_id general_links "$link_title"]

ns_db releasehandle $db

ns_return 200 text/html "
[ad_header "One Link"]

<h2>One Link</h2>

[ad_context_bar_ws [list "$return_url" "$return_title"] "One Link"]

<hr>

$link_html
$comments

[ad_footer]
"
