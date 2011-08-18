# $Id: post-new-2.tcl,v 3.0.4.1 2000/04/28 15:11:14 carsten Exp $
set_the_usual_form_variables

# subcategory_id

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

#check for the user cookie

set user_id [ad_get_user_id]

if {$user_id == 0} {
   ad_returnredirect /register.tcl?return_url=[ns_urlencode "[ns_conn url]"]
   return
}

# we know who this is
set db [ns_db gethandle]

set selection [ns_db 0or1row $db "select n.category_id, n.noun_for_about, primary_category, subcategory_1, pre_post_blurb, primary_maintainer_id, u.email as maintainer_email
from n_to_n_subcategories sc, n_to_n_primary_categories n, users u 
where sc.category_id = n.category_id
and n.primary_maintainer_id = u.user_id
and sc.subcategory_id = $subcategory_id"]

if [empty_string_p $selection] {
    ad_return_error "Couldn't find Subcategory $subcategory_id" "There is no subcategory
$subcategory_id\" in [neighbor_system_name]"
    return
}

set_variables_after_query

ReturnHeaders

ns_write "[neighbor_header "Post Step 2"]

<h2>Step 2</h2>

of posting a new $subcategory_1  story in [neighbor_home_link $category_id $primary_category]

<hr>

In order to keep the site easily browsable, if you're telling a story
about the same $noun_for_about as a previous poster,
then it would be good if you click on the name here rather than typing
it again (because you'd probably spell it differently).

<ul>

"

set selection [ns_db select $db "select distinct about
from neighbor_to_neighbor
where subcategory_id = $subcategory_id
and about is not null
order by upper(about)"]

set counter 0
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    incr counter
    ns_write "<li><a href=\"post-new-3.tcl?subcategory_id=$subcategory_id&about=[ns_urlencode $about]\">$about</a>\n"
}

if { $counter == 0 } {
    ns_write "no existing items found"
}

ns_write "
</ul>

<P>

Just click on one of the above names if you recognize it.  If not,
e.g., if you are telling a story about a new $noun_for_about, then 
enter the name here:

<form method=post action=post-new-3.tcl>
[export_form_vars subcategory_id]
<input type=text name=about size=20>
<input type=submit value=\"Add a new About Value to the Database\">
</form>
"

ns_write "[neighbor_footer $maintainer_email]"


