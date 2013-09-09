# /www/neighbor/by-about.tcl
ad_page_contract {
    Lists postings in a category, organized by the merchants they're referring to.

    @param category_id the id of the category to list.
    @param everything_p whether all of the listings should be posted, or only a certain number at a time (specified by the parameters file).
    @author Philip Greenspun (philg@mit.edu)
    @creation-date 1 January 1996
    @cvs-id by-about.tcl,v 3.1.6.4 2000/09/22 01:38:53 kevin Exp
} {
    category_id:integer,optional
    everything_p:integer,optional
}

if ![info exists category_id] {
    set category_id [ad_parameter DefaultPrimaryCategory neighbor]
}

set query_result [db_0or1row n_to_n_category_info_2 "select primary_category, top_title, top_blurb, approval_policy, regional_p, region_type, noun_for_about, decorative_photo, primary_maintainer_id, u.email as maintainer_email
from n_to_n_primary_categories n, users u 
where n.primary_maintainer_id = u.user_id
and n.category_id = :category_id"]

if [empty_string_p $query_result] {
    ad_return_error "Couldn't find Category $category_id" "There is no category
#$category_id\" in [neighbor_system_name]"
    return
}

set page_content "[neighbor_header "All $primary_category postings by $noun_for_about]"]

[ad_decorate_top "<h2>All postings by $noun_for_about</h2>

in [neighbor_home_link $category_id $primary_category]

<p>

(actually these are ranked by the \"about\" column in the database, which typically
contains a $noun_for_about)
" $decorative_photo]

<hr>
"

set sql_query "select neighbor_to_neighbor_id, users.email as poster_email, title, about, posted
from neighbor_to_neighbor, users
where category_id = :category_id
and neighbor_to_neighbor.approved_p = 't'
and neighbor_to_neighbor.poster_user_id = users.user_id 
order by about, posted desc"

append page_content "<ul>\n"

# we don't want a slow link loser tying up the database handle
# so we build a list items variable 

set list_items ""
set n_reasonable [ad_parameter NReasonablePostings neighbor 100]
set counter 0
db_foreach n_to_n_postings_by_merchant $sql_query {
    incr counter
    if [empty_string_p $title] {
	set anchor $about
    } else {
	set anchor "$about : $title"
    }
    if { (![info exists everything_p] || $everything_p == 0) && ($counter > $n_reasonable) } {
	append list_items "<p>
...
<p>
(<a href=\"by-about?everything_p=1&[export_url_vars category_id]\">list entire database</a>)
"
       break
    }
    append list_items "<li><a href=\"view-one?neighbor_to_neighbor_id=$neighbor_to_neighbor_id\">$anchor</a> (by $poster_email on $posted)\n"

}

db_release_unused_handles 

# we've kicked the database connection back into the pool; now let's
# stream out all the stuff to the user

append page_content $list_items

append page_content "</ul>

<p>

<IMG  WIDTH=16 HEIGHT=16 SRC=next.xbm><a href=\"post-new?[export_url_vars category_id]\">Post your own story</a>

[neighbor_footer $maintainer_email]
"

doc_return  200 text/html $page_content
