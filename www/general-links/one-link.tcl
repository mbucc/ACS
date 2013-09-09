# File: /general-links/one-link.tcl

ad_page_contract {
    Displays more link information.

    @param link_id the ID of the link
    @param return_title the title of the page to go back to
    @param return_url the URL of the page to go back to
    @creation-date: 2/01/2000
    @Author: tzumainn@arsdigita.com
    @cvs-id one-link.tcl,v 3.0.12.5 2000/09/22 01:38:04 kevin Exp
} {
    link_id:naturalnum,notnull
    {return_title "General Links"} 
    {return_url "index"}
}

page_validation {
if { [db_0or1row select_link_info "select link_id, creation_time, url, link_title, link_description
from general_links gl
where link_id=:link_id
"] ==0 } { 
	error "Link $link_id does not exist."
    }
}



if {[ad_parameter ClickthroughP general-links] == 1} {
    set exact_link "/ct/ad_link_${link_id}?send_to=$url"
} else {
    set exact_link "$url"
}

set link_html "<ul>
<li><a href=\"$exact_link\"><b>$link_title</b></a> - [ad_general_link_format_rating_result $link_id]
<p>$link_description
<p>Posted on [util_AnsiDatetoPrettyDate $creation_time]
<p>
[ad_general_link_format_rating $link_id "link-rate.tcl"]
<p>
</ul>"

set comments [ad_general_comments_list $link_id general_links "$link_title"]



doc_return  200 text/html "
[ad_header "One Link"]

<h2>One Link</h2>

[ad_context_bar_ws [list "$return_url" "$return_title"] "One Link"]

<hr>

$link_html
$comments

[ad_footer]
"
