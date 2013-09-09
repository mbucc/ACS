# /www/bookmarks/one-host-public.tcl

ad_page_contract {

    All the (public) URLs that start with a particular host
    
    @param url particular host url
    @author  philg@mit.edu
    @created November 7, 1999
    @cvs-id  one-host-public.tcl,v 3.1.2.6 2000/09/22 01:37:03 kevin Exp
} {
    {url}
}

set page_content "[ad_header "Bookmarks for $url"]
<h2>Bookmarks for $url</h2>

[ad_context_bar_ws_or_index \
	[list "" "Bookmarks"]  \
	[list "public-bookmarks" "Public"] \
	[list "most-popular-public" "Most Popular"] \
	"One URL"]

<hr>

<ul>
"

set old_name ""

db_foreach bookmarks_by_host {
    select u.first_names || ' ' || u.last_name as name, 
           complete_url
    from   users u, 
           bm_list bml, 
           bm_urls bmu
    where  u.user_id = bml.owner_id
    and    bml.url_id = bmu.url_id
    and    bml.private_p <> 't'
    and    bmu.host_url = :url
    order by name
} {
    if [string compare $old_name $name] {
	append page_content "<h4>$name</h4>\n"
	set old_name $name
    }

    append page_content "<li><a href=\"$complete_url\">$complete_url</a>\n"
}

db_release_unused_handles

append page_content "</ul>

[ad_admin_footer]
"

# --serve the page -----------
doc_return  200 text/html $page_content
