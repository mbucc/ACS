# /admin/bookmarks/one-host.tcl
#
# Shows who bookmarked a URL
#
# jsc@arsdigita.com, July 1999
#
# $Id: one-host.tcl,v 3.0.4.1 2000/03/15 21:15:29 aure Exp $

ad_page_variables {url}

set db [ns_db gethandle]

set html "[ad_admin_header "Bookmarks for $url"]
<h2>Bookmarks for $url</h2>

[ad_admin_context_bar [list "" "Bookmarks"] [list "most-popular" "Most Popular"] "Bookmarks for $url"]

<hr>

<ul>"

set selection [ns_db select $db "
select u.first_names || ' ' || u.last_name as name, 
       complete_url
from   users u, bm_list bml, bm_urls bmu
where  u.user_id = bml.owner_id
and    bml.url_id = bmu.url_id
and    bmu.host_url = '$QQurl'
order by name"]

set old_name ""

while { [ns_db getrow $db $selection] } {
    set_variables_after_query

    if { $old_name != $name } {
	append html "<h4>$name</h4>\n"
	set old_name $name
    }

    append html "<li><a href=\"$complete_url\">$complete_url</a>\n"
}

append html "</ul>

[ad_admin_footer]"

# release the database handle
ns_db releasehandle $db

# serve the page
ns_return 200 text/html $html