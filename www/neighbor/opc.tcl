# $Id: opc.tcl,v 3.0.4.1 2000/03/16 18:19:32 bcameros Exp $
# opc.tcl stands for "one primary category"

set_the_usual_form_variables

# category_id

set db [neighbor_db_gethandle]

set selection [ns_db 0or1row $db "select primary_category, top_title, top_blurb, approval_policy, regional_p, region_type, noun_for_about, decorative_photo, primary_maintainer_id, u.first_names || ' ' || u.last_name as maintainer_name 
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

ns_write "[neighbor_header "[neighbor_system_name]: $primary_category"]\n"

if [empty_string_p $top_title] {
    set top_title "$primary_category Postings"
}


if [empty_string_p $decorative_photo] {
    # write a plain headline
    ns_write "<h2>$top_title</h2>

in [neighbor_uplink]
"
} else {
    # write table including the picture
    ns_write "
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

ns_write "
<hr>

$top_blurb

<ul>

"

set count 0

# let's make sure that we aren't going to eval an unsafe express
validate_integer "category_id" $category_id
foreach sublist [util_memoize "neighbor_summary_items_approved $category_id" 900] {
    set id [lindex $sublist 0]
    set name [lindex $sublist 1]
    set n_items [lindex $sublist 2]
    incr count
    ns_write "<li><a href=\"one-subcategory.tcl?id=$id\">$name</a> ($n_items)\n"
}

ns_write "

</ul>

You can also look at all the postings
<a href=\"by-about.tcl?[export_url_vars category_id]\">by $noun_for_about</a>
or 
<a href=\"by-date.tcl?[export_url_vars category_id]\">by date</a>

<p>

"

if [ad_parameter ProvideLocalSearchP neighbor 1] {
    if [ad_parameter UseContext neighbor 0] {
	set form_target "search-ctx.tcl"
    } else {
	# we'll just use our pseudo_contains sequential search thing
	set form_target "search.tcl"
    }
    ns_write "
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
    ns_write "Help the community by <a href=\"post-new.tcl?category_id=$category_id\">posting a new story</a>.\n"
}

ns_write "

[neighbor_footer]

"


