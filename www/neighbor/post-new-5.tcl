# $Id: post-new-5.tcl,v 3.0.4.1 2000/04/28 15:11:14 carsten Exp $
set_the_usual_form_variables

# everything for a neighbor_to_neighbor posting

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

# check for the user cookie; they shouldn't ever get here

set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
   ad_returnredirect /register.tcl
   return
}
set db [ns_db gethandle]

set selection [ns_db 0or1row $db "select n.category_id, n.noun_for_about, primary_category, subcategory_1, pre_post_blurb, approval_policy, primary_maintainer_id, u.email as maintainer_email
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

if { ![info exists subcategory_id] || [empty_string_p $subcategory_id] } {
    append exception_text "<li>Your browser (or maybe our software) dropped the category of posting.  Ouch!"
    incr exception_count
}

if { ![info exists about] || [empty_string_p $about] } {
    append exception_text "<li>Your browser dropped the about field for this posting."
    incr exception_count
}

if { ![info exists title] || [empty_string_p $title] } {
    append exception_text "<li>Your browser dropped the title for this posting."
    incr exception_count
}

if { ![info exists body] || ![regexp {[A-Za-z]} $body] } {
    append exception_text "<li>Your browser dropped your story!"
    incr exception_count
}

if { $exception_count != 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

# no exceptions

ReturnHeaders

ns_write "[neighbor_header "Inserting Story"]

<h2>Inserting Story</h2>

into [neighbor_home_link $category_id $primary_category]

<hr>

"

set creation_ip_address [ns_conn peeraddr]

if { $approval_policy == "open" } {
    set approved_p "t"
} else {
    set approved_p "f"
}


if { [string length $QQbody] < 4000 } {
    # pathetic Oracle can handle the string literal
    ns_db dml $db "insert into neighbor_to_neighbor
(neighbor_to_neighbor_id, poster_user_id, posted, creation_ip_address, category_id, subcategory_id, about, title, body, html_p, approved_p)
values
($neighbor_to_neighbor_id, $user_id, sysdate, '$creation_ip_address', $category_id, $subcategory_id,'$QQabout','$QQtitle','$QQbody','$html_p','$approved_p')"
} else {
    # pathetic Oracle must be fed the full story via the bizzarro
    # clob extensions 
    ns_ora clob_dml $db "insert into neighbor_to_neighbor
(neighbor_to_neighbor_id, poster_user_id, posted, creation_ip_address, category_id, subcategory_id, about, title, body, html_p, approved_p)
values
($neighbor_to_neighbor_id, $user_id, sysdate, '$creation_ip_address', $category_id, $subcategory_id,'$QQabout','$QQtitle',empty_clob(),'$html_p','$approved_p')
returning body into :one" $body
}

ns_write "Success!

<p>

There isn't much more to say.

[neighbor_footer $maintainer_email]
"
