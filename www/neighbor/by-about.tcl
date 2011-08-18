# $Id: by-about.tcl,v 3.0 2000/02/06 03:49:34 ron Exp $
set_form_variables 0

# category_id, everything_p 

if ![info exists category_id] {
    set category_id [ad_parameter DefaultPrimaryCategory neighbor]
}

set db [neighbor_db_gethandle]
set selection [ns_db 0or1row $db "select primary_category, top_title, top_blurb, approval_policy, regional_p, region_type, noun_for_about, decorative_photo, primary_maintainer_id, u.email as maintainer_email
from n_to_n_primary_categories n, users u 
where n.primary_maintainer_id = u.user_id
and n.category_id = $category_id"]

if [empty_string_p $selection] {
    ad_return_error "Couldn't find Category $category_id" "There is no category
#$category_id\" in [neighbor_system_name]"
    return
}

set_variables_after_query
   
ReturnHeaders

ns_write "[neighbor_header "All $primary_category postings by $noun_for_about]"]

[ad_decorate_top "<h2>All postings by $noun_for_about</h2>

in [neighbor_home_link $category_id $primary_category]

<p>

(actually these are ranked by the \"about\" column in the database, which typically
contains a $noun_for_about)
" $decorative_photo]

<hr>
"

set selection [ns_db select $db "select neighbor_to_neighbor_id, users.email as poster_email, title, about, posted
from neighbor_to_neighbor, users
where category_id = $category_id
and neighbor_to_neighbor.approved_p = 't'
and neighbor_to_neighbor.poster_user_id = users.user_id 
order by about, posted desc"]

ns_write "<ul>\n"

# we don't want a slow link loser tying up the database handle
# so we build a list items variable 

set list_items ""
set n_reasonable [ad_parameter NReasonablePostings neighbor 100]
set counter 0
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
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
(<a href=\"by-about.tcl?everything_p=1&[export_url_vars category_id]\">list entire database</a>)
"
	ns_db flush $db 
	break
    }
    append list_items "<li><a href=\"view-one.tcl?neighbor_to_neighbor_id=$neighbor_to_neighbor_id\">$anchor</a> (by $poster_email on $posted)\n"

}

ns_db releasehandle $db 

# we've kicked the database connection back into the pool; now let's
# stream out all the stuff to the user

ns_write $list_items

ns_write "</ul>

<p>

<IMG  WIDTH=16 HEIGHT=16 SRC=next.xbm><a href=\"post-new.tcl?[export_url_vars category_id]\">Post your own story</a>

[neighbor_footer $maintainer_email]
"

