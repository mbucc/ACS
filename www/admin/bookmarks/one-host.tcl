# /www/admin/bookmarks/one-host.tcl

ad_page_contract {
    Shows who bookmarked a URL
    @param url the URL to check
    @author Jin Choi (jsc@arsdigita.com)
    @creation-date July 1999  
    @cvs-id one-host.tcl,v 3.1.8.5 2000/09/22 01:34:24 kevin Exp
} {
    {url:trim}
} 

set html "[ad_admin_header "Bookmarks for $url"]
<h2>Bookmarks for $url</h2>

[ad_admin_context_bar [list "" "Bookmarks"] [list "most-popular" "Most Popular"] "Bookmarks for $url"]

<hr>

<ul>"

set old_name ""

db_foreach bookmark {
    select u.first_names || ' ' || u.last_name as name, 
           complete_url
    from   users u, 
           bm_list bml, 
           bm_urls bmu
    where  u.user_id = bml.owner_id
    and    bml.url_id = bmu.url_id
    and    bmu.host_url = :url
    order by name
} {
    if { $old_name != $name } {
	append html "<h4>$name</h4>\n"
	set old_name $name
    }

    append html "<li><a href=\"$complete_url\">$complete_url</a>\n"
}

append html "</ul>

[ad_admin_footer]"

# release the database handle
db_release_unused_handles

# serve the page
doc_return  200 text/html $html

