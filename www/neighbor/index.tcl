# /www/neighbor/index.tcl

ad_page_contract {
    Front page of the Neighbor to Neighbor system.  Lists all of the
    active categories, or if there is a default primary category
    redirects to that page.  

    @author Philip Greenspun (philg@mit.edu)
    @creation-date 1 January 1996
    @cvs-id index.tcl,v 3.4.2.4 2000/09/22 01:38:55 kevin Exp
} {} 

if { [ad_parameter OnlyOnePrimaryCategoryP neighbor 0] && ![empty_string_p [ad_parameter DefaultPrimaryCategory neighbor]] } {
    # this is only one category; send them straight there
    ad_returnredirect "opc?category_id=[ad_parameter DefaultPrimaryCategory neighbor]"
    return
}

set page_content "[neighbor_header [neighbor_system_name]]

<h2>Neighbor to Neighbor</h2>

in [ad_site_home_link] 

<hr>

<ul>
"

db_foreach n_to_n_primary_categories {
    select category_id, 
           primary_category 
    from   n_to_n_primary_categories
    where  (active_p = 't' or active_p is null)
    order by upper(primary_category)
} {
    append page_content "<li><a href=opc?category_id=$category_id>$primary_category</a>\n"
}

append page_content "
</ul>

[neighbor_footer]
"

doc_return  200 text/html $page_content
