# /admin/bookmarks/most-popular.tcl
#
# figures out the most popular hosts and urls in the system
#
# aure@arsdigita.com, June 1999
#
# $Id: most-popular.tcl,v 3.0.4.2 2000/03/15 21:21:02 aure Exp $

set title "Most Popular Bookmarks"
set max_hosts 10
set max_urls 20

set page_content "[ad_admin_header $title]

<h2>$title</h2>

[ad_admin_context_bar [list "" "Bookmarks"]  $title]

<hr>

<h3>Most Popular Hosts</h3>

<ul>"

set db [ns_db gethandle main]

# get the most popular hosts

set selection [ns_db select $db "
    select host_url, count(*) as n_bookmarks
    from   bm_list, bm_urls
    where  bm_list.url_id = bm_urls.url_id
    group by host_url
    order by n_bookmarks desc"]

set counter 0
while {[ns_db getrow $db $selection] && $counter < $max_hosts} {
    incr counter
    set_variables_after_query

    regsub {^http://([^/]*)/?} $host_url {\1} hostname
    append page_content "<li>$n_bookmarks: <a href=\"one-host?url=[ns_urlencode $host_url]\">$hostname</a>"
}
if {$counter==$max_hosts} {
    ns_db flush $db
}

# get the most popular urls

append page_content "</ul>\n\n<h3>Most Popular URLs</h3>\n\n<ul>\n"

set selection [ns_db select $db "
    select complete_url, url_title, count(*) as n_bookmarks
    from   bm_list, bm_urls
    where  bm_list.url_id = bm_urls.url_id
    group  by complete_url, url_title
    order by n_bookmarks desc"]

set counter 0
while {[ns_db getrow $db $selection] && $counter < $max_urls} {
    incr counter
    set_variables_after_query
    if [empty_string_p $url_title] {
	set url_title $complete_url
    }
    append page_content "
    <li>$n_bookmarks: <a href=$complete_url>$url_title</a>"
}
if {$counter == $max_urls} {
    ns_db flush $db
}

append page_content "</ul>[ad_admin_footer]"

# release the database handle
ns_db releasehandle $db

# serve the page
ns_return 200 text/html $page_content


