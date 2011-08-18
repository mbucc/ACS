# $Id: most-popular-public.tcl,v 3.0 2000/02/06 03:35:36 ron Exp $
# /bookmarks/most-popular-public.tcl
#
# prints a report of the most popular hosts and urls in the system
#
# by philg@mit.edu on November 7, 1999
#
# copied from /admin/bookmarks/most-popular.tcl but limited 
# to public_p
#


set title "Most Popular Public Bookmarks"
set max_hosts 10
set max_urls 20


set html "[ad_header $title]

<h2>$title</h2>

[ad_context_bar_ws_or_index [list "index.tcl" "Bookmarks"]  [list "public-bookmarks.tcl" "Public"] $title]

<hr>

<h3>Most Popular Hosts</h3>

<ul>
"

set db [ns_db gethandle main]

# -- get the most popular hosts -----------
set selection [ns_db select $db "select host_url, count(*) as n_bookmarks
from bm_urls, bm_list
where bm_urls.url_id = bm_list.url_id
and bm_list.private_p <> 't'
group by host_url
order by n_bookmarks desc"]

set counter 0
while {[ns_db getrow $db $selection] && $counter < $max_hosts} {
    incr counter
    set_variables_after_query

    regsub {^http://([^/]*)/?} $host_url {\1} hostname
    append html "<li>$n_bookmarks: <a href=\"one-host-public.tcl?url=[ns_urlencode $host_url]\">$hostname</a>"
}
if {$counter==$max_hosts} {
    ns_db flush $db
}

# -- get the most popular urls ----------------
append html "</ul>\n\n<h3>Most Popular URLs</h3>\n\n<ul>\n"

set selection [ns_db select $db "select complete_url, url_title, count(*) as n_bookmarks
from bm_urls, bm_list
where bm_urls.url_id = bm_list.url_id
and bm_list.private_p <> 't'
group by complete_url, url_title
order by n_bookmarks desc"]

set counter 0
while {[ns_db getrow $db $selection] && $counter < $max_urls} {
    incr counter
    set_variables_after_query
    if [empty_string_p $url_title] {
	set url_title $complete_url
    }
    append html "<li>$n_bookmarks: <a href=$complete_url>$url_title</a>"
}
if {$counter==$max_urls} {
    ns_db flush $db
}

append html "</ul>[ad_footer  ]"

ns_db releasehandle $db

# --serve the page ------------------------
ns_return 200 text/html $html


