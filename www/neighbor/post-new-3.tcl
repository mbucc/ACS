# $Id: post-new-3.tcl,v 3.0.4.1 2000/04/28 15:11:14 carsten Exp $
set_the_usual_form_variables

# subcategory_id, about

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

set exception_text ""
set exception_count 0

if { ![info exists about] || $about == "" } {
    append exception_text "<li>You didn't choose an about field for your posting. (or your browser dropped it)\n"
    incr exception_count
}

if { $exception_count != 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

ReturnHeaders

ns_write "[neighbor_header "Post Step 3"]

<h2>Step 3</h2>

of posting a new $subcategory_1 story in [neighbor_home_link $category_id $primary_category]

<hr>

<form method=post action=post-new-4.tcl>
[export_form_vars subcategory_id about]

<p>

Give us a one-line summary of your posting, something that will let
someone know whether or not they want to read the full story.  Note
that this will appear with the about field (\"$about\") in front of
it, so you don't have to repeat the name of the merchant, camera, etc.

<p>

$about : <input type=text name=title size=50>

<p>

Give us the full story, taking as much space as you need.

<p>

<textarea name=body rows=8 cols=70 wrap=soft>

</textarea>

<br>

The above story is in <select name=html_p><option value=f>Plain Text<option value=t>HTML</select>


<p>


<center>
<input type=submit value=\"Preview Story\">
</center>


[neighbor_footer]
"
