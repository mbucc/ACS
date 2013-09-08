# /www/admin/bookmarks/most-popular.tcl

ad_page_contract {
    figures out the most popular hosts and urls in the system
    @author Aurelius Prochazka (aure@arsdigita.com)
    @creation-date June 1999  
    @cvs-id most-popular.tcl,v 3.2.2.5 2000/09/22 01:34:24 kevin Exp
} {} 

set title "Most Popular Bookmarks"
set max_hosts 10
set max_urls 20

set page_content "[ad_admin_header $title]

<h2>$title</h2>

[ad_admin_context_bar [list "" "Bookmarks"]  $title]

<hr>

<h3>Most Popular Hosts</h3>

<ul>"

# get the most popular hosts
set counter 0

db_foreach popular_hosts {
    select host_url, count(*) as n_bookmarks
    from   bm_list, bm_urls
    where  bm_list.url_id = bm_urls.url_id
    group by host_url
    order by n_bookmarks desc
} {
    incr counter
    regsub {^http://([^/]*)/?} $host_url {\1} hostname
    append page_content "<li>$n_bookmarks: <a href=\"one-host?url=[ns_urlencode $host_url]\">$hostname</a>"
}

# get the most popular urls
set counter 0
append page_content "</ul>\n\n<h3>Most Popular URLs</h3>\n\n<ul>\n"
db_foreach popular_urls {
    select complete_url, url_title, count(*) as n_bookmarks
    from   bm_list, bm_urls
    where  bm_list.url_id = bm_urls.url_id
    group  by complete_url, url_title
    order by n_bookmarks desc
} {
    incr counter

    if [empty_string_p $url_title] {
	set url_title $complete_url
    }
    append page_content "
    <li>$n_bookmarks: <a href=$complete_url>$url_title</a>"
}

append page_content "</ul>[ad_admin_footer]"

# release the database handle
db_release_unused_handles

# serve the page
doc_return  200 text/html $page_content

