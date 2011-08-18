# $Id: post-new-4.tcl,v 3.0.4.1 2000/04/28 15:11:14 carsten Exp $
set_the_usual_form_variables

# subcategory_id, about, title, body, html_p

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

if { ![info exists title] || $title == "" } {
    append exception_text "<li>You forgot to type a one-line summary of your story."
    incr exception_count
}

if { ![info exists body] || ![regexp {[A-Za-z]} $body] } {
    append exception_text "<li>You forgot to type your story!"
    incr exception_count
}

if { [info exists title] && $title != "" && ![regexp {[a-z]} $title] } {
    append exception_text "<li>Your one line summary appears to be all uppercase.  ON THE INTERNET THIS IS CONSIDERED SHOUTING.  IT IS ALSO MUCH HARDER TO READ THAN MIXED CASE TEXT.  So we don't allow it, out of decorum and consideration for people who may be visually impaired."
    incr exception_count
}

if { [info exists body] && $body != "" && ![regexp {[a-z]} $body] } {
    append exception_text "<li>Your story appears to be all uppercase.  ON THE INTERNET THIS IS CONSIDERED SHOUTING.  IT IS ALSO MUCH HARDER TO READ THAN MIXED CASE TEXT.  So we don't allow it, out of decorum and consideration for people who may be visually impaired."
    incr exception_count
}

if { $exception_count != 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}



if { $exception_count != 0 } {
    ns_return 200 text/html [neighbor_error_page $exception_count $exception_text]
    return
}

# no exceptions

ReturnHeaders

ns_write "[neighbor_header "Previewing Story"]

<h2>Previewing Story</h2>

before stuffing it into [neighbor_home_link $category_id $primary_category]


<hr>

<h3>What viewers of a summary list will see</h3>

$about : $title

<h3>The full story</h3>

<blockquote>
"

if { [info exists html_p] && $html_p == "t" } {
    ns_write "$body
</blockquote>

Note: if the story has lost all of its paragraph breaks then you
probably should have selected \"Plain Text\" rather than HTML.  Use
your browser's Back button to return to the submission form.
"

} else {
    ns_write "[util_convert_plaintext_to_html $body]
</blockquote>

Note: if the story has a bunch of visible HTML tags then you probably
should have selected \"HTML\" rather than \"Plain Text\".  Use your
browser's Back button to return to the submission form.  " 
}

ns_write "
</blockquote>

"

set neighbor_to_neighbor_id [database_to_tcl_string $db "select neighbor_sequence.nextval from dual"]

ns_write "
<form method=POST action=post-new-5.tcl>
[export_form_vars neighbor_to_neighbor_id]
[export_entire_form]
<center>
<input type=submit value=\"Confirm\">
</center>
</form>


[neighbor_footer $maintainer_email]
"
