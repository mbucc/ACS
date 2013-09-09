# /www/bookmarks/most-popular-public.tcl

ad_page_contract {
    prints a report of the most popular hosts and urls in the system
    copied from /admin/bookmarks/most-popular.tcl but limited to public_p
    @author Philip Greenspun (philg@mit.edu)
    @creation-date November 7 1999  
    @cvs-id most-popular-public.tcl,v 3.2.2.5 2000/09/22 01:37:03 kevin Exp
} {} 

set title "Most Popular Public Bookmarks"
set max_hosts 10
set max_urls 20

set html "[ad_header $title]

<h2>$title</h2>

[ad_context_bar_ws_or_index [list "index" "Bookmarks"]  [list "public-bookmarks" "Public"] $title]

<hr>

<h3>Most Popular Hosts</h3>

<ul>
"

# -- get the most popular hosts -----------
set counter 0

db_foreach popular_hosts {
    select host_url, 
           count(*) as n_bookmarks
    from   bm_urls, bm_list
    where  bm_urls.url_id = bm_list.url_id
    and    bm_list.private_p <> 't'
    group by host_url
    order by n_bookmarks desc
} {

    if { $counter < $max_hosts } {
	incr counter
	regsub {^http://([^/]*)/?} $host_url {\1} hostname
	append html "<li>$n_bookmarks: <a href=\"one-host-public?url=[ns_urlencode $host_url]\">$hostname</a>"
    }
}

# -- get the most popular urls ----------------
append html "</ul>\n\n<h3>Most Popular URLs</h3>\n\n<ul>\n"

db_foreach popular_urls {
    select complete_url, 
           url_title, 
           count(*) as n_bookmarks
    from   bm_urls, bm_list
    where  bm_urls.url_id = bm_list.url_id
    and    bm_list.private_p <> 't'
    group by complete_url, 
             url_title
    order by n_bookmarks desc
} {
    if { $counter < $max_urls } {
    incr counter

	if [empty_string_p $url_title] {
	    set url_title $complete_url
	}
	append html "<li>$n_bookmarks: <a href=$complete_url>$url_title</a>"
    }
}

append html "</ul>[ad_footer  ]"

db_release_unused_handles

# --serve the page ------------------------
doc_return  200 text/html $html






