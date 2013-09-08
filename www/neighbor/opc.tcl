# /www/neighbor/opc.tcl
ad_page_contract {
    Lists postings in the selected primary category.

    @param category_id id of the selected primary category.
    @author Philip Greenspun (philg@mit.edu)
    @creation-date 1 January 1996
    @cvs-id opc.tcl,v 3.4.2.3 2000/09/22 01:38:55 kevin Exp
} {
    category_id:integer
}

set query_result [db_0or1row n_to_n_category_info "select primary_category, top_title, top_blurb, approval_policy, regional_p, region_type, noun_for_about, decorative_photo, primary_maintainer_id, u.first_names || ' ' || u.last_name as maintainer_name 
from n_to_n_primary_categories n, users u 
where n.primary_maintainer_id = u.user_id
and n.category_id = :category_id"]

if {$query_result != 1} {
    ad_return_error "Couldn't find Category $category_id" "There is no category
#$category_id\" in [neighbor_system_name]"
    return
}

db_release_unused_handles

set page_content "[neighbor_header "[neighbor_system_name]: $primary_category"]\n"

if [empty_string_p $top_title] {
    set top_title "$primary_category Postings"
}

if [empty_string_p $decorative_photo] {
    # write a plain headline
    append page_content "<h2>$top_title</h2>

in [neighbor_uplink]
"
} else {
    # write table including the picture
    append page_content "
<table>
<tr>
<td>
$decorative_photo
<td>
<h2>$top_title</h2>

in [neighbor_uplink]

</tr>
</table>
"
}

append page_content "
<hr>

$top_blurb

<ul>

"

set count 0

foreach sublist [util_memoize "neighbor_summary_items_approved $category_id" 900] {
    set id [lindex $sublist 0]
    set name [lindex $sublist 1]
    set n_items [lindex $sublist 2]
    incr count
    append page_content "<li><a href=\"one-subcategory?id=$id\">$name</a> ($n_items)\n"
}

append page_content "

</ul>

You can also look at all the postings
<a href=\"by-about?[export_url_vars category_id]\">by $noun_for_about</a>
or 
<a href=\"by-date?[export_url_vars category_id]\">by date</a>

<p>

"

if [ad_parameter ProvideLocalSearchP neighbor 1] {
    if [ad_parameter UseContext neighbor 0] {
	set form_target "search-ctx"
    } else {
	# we'll just use our pseudo_contains sequential search thing
	set form_target "search"
    }
    append page_content "
<form action=\"$form_target\" method=GET>

or search by keyword:  <input type=text name=query_string size=25>

<input type=submit value=\"Submit\">

<p>

(this searches through the full text of all the postings, plus the
names and email addresses of the posters)

</form>

"
}

if { $approval_policy != "closed" } {
    append page_content "Help the community by <a href=\"post-new?category_id=$category_id\">posting a new story</a>.\n"
}

append page_content "

[neighbor_footer]

"

doc_return  200 text/html $page_content
