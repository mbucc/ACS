# $Id: one-subcategory.tcl,v 3.0 2000/02/06 03:49:52 ron Exp $
set_form_variables

# id 

set db [ns_db gethandle]
set selection [ns_db 0or1row $db "select n.category_id, n.noun_for_about, n.primary_category, n.primary_maintainer_id, n.decorative_photo, 
sc.subcategory_id, sc.subcategory_1, sc.decorative_photo as sub_photo, sc.publisher_hint,
u.email as maintainer_email
from n_to_n_subcategories sc, n_to_n_primary_categories n, users u 
where sc.category_id = n.category_id
and n.primary_maintainer_id = u.user_id
and sc.subcategory_id = $id"]

if [empty_string_p $selection] {
    ad_return_error "Couldn't find Subcategory $id" "There is no subcategory
\"$id\" in [neighbor_system_name]"
    return
}

set_variables_after_query

ReturnHeaders

set the_title "$subcategory_1 Postings"
set headline_and_uplink "\n<h2>$subcategory_1 Postings</h2>\n\nin [neighbor_home_link $category_id $primary_category]\n"

ns_write "[neighbor_header $the_title]\n"

if [empty_string_p $decorative_photo] {
    ns_write $headline_and_uplink
} else {
    ns_write "<table><tr><td>$decorative_photo</td><td>$headline_and_uplink</td></tr></table>\n"
}

if { [info exists by_date_p] && $by_date_p == "t" } {
    ns_write "<p>(also available <a href=\"one-subcategory.tcl?id=$id&by_date_p=f\">sorted by $noun_for_about</a>)"
    set order_by "order by posted desc"
} else {
    ns_write "<p>(also available <a href=\"one-subcategory.tcl?id=$id&by_date_p=t\">sorted by date</a>)"
    set order_by "order by sort_key, posted desc"
}

ns_write "
<hr>

$publisher_hint

$sub_photo

<ul>

"

set selection [ns_db select $db "select neighbor_to_neighbor_id, title, posted, about, upper(about) as sort_key, users.user_id, users.first_names || ' ' || users.last_name as poster_name
from neighbor_to_neighbor, users
where subcategory_id = $id
and (expires > sysdate or expires is NULL)
and neighbor_to_neighbor.poster_user_id = users.user_id
and neighbor_to_neighbor.approved_p = 't'
$order_by"]

# these can be extensive and we don't want someone on a slow link
# tying up the database connection, so we build up a big string 

set moby_string ""
set last_about ""
set first_pass 1
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
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
    append moby_string "<li><a href=\"view-one.tcl?neighbor_to_neighbor_id=$neighbor_to_neighbor_id\">$anchor</a>
 -- $poster_name, [util_AnsiDatetoPrettyDate $posted]"
}

ns_db releasehandle $db

# we've released the db handle; now a slow modem user can't hold up the server

ns_write $moby_string

ns_write "</ul>

<p>

Please contribute to making this a useful service by
<a href=\"post-new.tcl?[export_url_vars category_id]\">posting your own story</a>.

[neighbor_footer]
"
