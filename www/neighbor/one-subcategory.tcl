# /www/neighbor/one-subcategory.tcl
ad_page_contract {
    Displays neighbor-to-neighbor entries in a specific category.

    @author Philip Greenspun (philg@mit.edu)
    @creation-date 1 January 1998
    @cvs-id one-subcategory.tcl,v 3.1.6.3 2000/09/22 01:38:55 kevin Exp
    @param id the category to display
} {
    id:integer,notnull
}

set sql_query "
  select n.category_id, n.noun_for_about, n.primary_category, 
         n.primary_maintainer_id, n.decorative_photo, 
         sc.subcategory_id, sc.subcategory_1, 
         sc.decorative_photo as sub_photo, sc.publisher_hint,
         u.email as maintainer_email
    from n_to_n_subcategories sc, n_to_n_primary_categories n, users u 
   where sc.category_id = n.category_id
     and n.primary_maintainer_id = u.user_id
     and sc.subcategory_id = $id"

if {![db_0or1row select_category $sql_query]} {
    db_release_unused_handles
    ad_return_error "Couldn't find Subcategory $id" "There is no subcategory
\"$id\" in [neighbor_system_name]"
    return
}

set the_title "$subcategory_1 Postings"
set headline_and_uplink "\n<h2>$subcategory_1 Postings</h2>\n\nin [neighbor_home_link $category_id $primary_category]\n"

set page_content "[neighbor_header $the_title]\n"

if [empty_string_p $decorative_photo] {
    append page_content $headline_and_uplink
} else {
    append page_content "<table><tr><td>$decorative_photo</td><td>$headline_and_uplink</td></tr></table>\n"
}

if { [info exists by_date_p] && $by_date_p == "t" } {
    append page_content "<p>(also available <a href=\"one-subcategory?id=$id&by_date_p=f\">sorted by $noun_for_about</a>)"
    set order_by "order by posted desc"
} else {
    append page_content "<p>(also available <a href=\"one-subcategory?id=$id&by_date_p=t\">sorted by date</a>)"
    set order_by "order by sort_key, posted desc"
}

append page_content "
<hr>

$publisher_hint

$sub_photo

<ul>

"

set sql_query "
  select neighbor_to_neighbor_id, title, posted, about, 
         upper(about) as sort_key, users.user_id, 
         users.first_names || ' ' || users.last_name as poster_name
    from neighbor_to_neighbor, users
   where subcategory_id = $id
     and (expires > sysdate or expires is NULL)
     and neighbor_to_neighbor.poster_user_id = users.user_id
     and neighbor_to_neighbor.approved_p = 't'
  $order_by"

# these can be extensive and we don't want someone on a slow link
# tying up the database connection, so we build up a big string 

set moby_string ""
set last_about ""
set first_pass 1
db_foreach select_entries $sql_query {
    if { $sort_key != $last_about } {
	if { $first_pass != 1 } {
	    # not first time through, separate
	    append moby_string "<p>\n"
	}
	set first_pass 0
	set last_about $sort_key
    }
    if [empty_string_p $title] {
	set anchor $about
    } else {
	set anchor "$about : $title"
    }
    append moby_string "<li><a href=\"view-one?neighbor_to_neighbor_id=$neighbor_to_neighbor_id\">$anchor</a>
 -- $poster_name, [util_AnsiDatetoPrettyDate $posted]"
}


append page_content $moby_string

append page_content "</ul>

<p>

Please contribute to making this a useful service by
<a href=\"post-new?[export_url_vars category_id]\">posting your own story</a>.

[neighbor_footer]
"

db_release_unused_handles

# we've released the db handle; now a slow modem user can't hold up the server
doc_return 200 text/html $page_content