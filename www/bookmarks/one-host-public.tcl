# $Id: one-host-public.tcl,v 3.0 2000/02/06 03:35:37 ron Exp $
# /bookmarks/one-host-public.tcl
#
# all the (public) URLs that start with a particular host
#
# philg@mit.edu on November 7, 1999
# 

set_the_usual_form_variables

# url

set db [ns_db gethandle]

set html "[ad_header "Bookmarks for $url"]
<h2>Bookmarks for $url</h2>

[ad_context_bar_ws_or_index [list "index.tcl" "Bookmarks"]  [list "public-bookmarks.tcl" "Public"] [list "most-popular-public.tcl" "Most Popular"] "One URL"]

<hr>

<ul>
"

set selection [ns_db select $db "select u.first_names || ' ' || u.last_name as name, complete_url
from users u, bm_list bml, bm_urls bmu
where u.user_id = bml.owner_id
  and bml.url_id = bmu.url_id
  and bml.private_p <> 't'
  and bmu.host_url = '$QQurl'
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

[ad_admin_footer]
"

ns_db releasehandle $db


# --serve the page -----------
ns_return 200 text/html $html
