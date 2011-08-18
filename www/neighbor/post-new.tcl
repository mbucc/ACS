# $Id: post-new.tcl,v 3.0.4.1 2000/04/28 15:11:14 carsten Exp $
set_the_usual_form_variables

# category_id

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

#check for the user cookie

set user_id [ad_get_user_id]

if {$user_id == 0} {
   ad_returnredirect /register.tcl?return_url=[ns_urlencode "[ns_conn url]?[export_url_vars category_id]"]
   return
}

# we know who this is
set db [ns_db gethandle]

set selection [ns_db 0or1row $db "select primary_category, pre_post_blurb, primary_maintainer_id, u.email as maintainer_email
from n_to_n_primary_categories n, users u 
where n.primary_maintainer_id = u.user_id
and n.category_id = $category_id"]

if [empty_string_p $selection] {
    ad_return_error "Couldn't find Category $category_id" "There is no category
$category_id\" in [neighbor_system_name]"
    return
}

set_variables_after_query


ReturnHeaders

ns_write "[neighbor_header "Prepare New Post"]

<h2>Prepare a New Posting</h2>

in [neighbor_home_link $category_id $primary_category]

<hr>
<h3>Pick a Category</h3>

<ul>

"


set selection [ns_db select $db "select subcategory_id, subcategory_1
from n_to_n_subcategories
where category_id = $category_id"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    ns_write "<li><a href=\"post-new-2.tcl?subcategory_id=$subcategory_id\">$subcategory_1</a>\n"
}

ns_write "

</ul>

$pre_post_blurb

[neighbor_footer $maintainer_email]
"
