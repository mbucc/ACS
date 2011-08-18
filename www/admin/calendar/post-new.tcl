# $Id: post-new.tcl,v 3.0.4.1 2000/04/28 15:08:27 carsten Exp $
# 
# this page exists to solicit from the user what kind of an event
# 

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set user_id [ad_get_user_id]
if { $user_id == 0 } {
    ad_returnredirect "/register/index.tcl?return_url=[ns_urlencode [ns_conn url]?category=$category]"
    return
}

ReturnHeaders
ns_write "[ad_admin_header "Pick Category"]

<h2>Pick Category</h2>

[ad_admin_context_bar [list "index.tcl" "Calendar"] "Pick Category"]

<hr>

<ul>
"

set db [ns_db gethandle]

set counter 0
foreach category [database_to_tcl_list $db "select category from calendar_categories where enabled_p = 't'"] {
    incr counter
    ns_write "<li><a href=\"post-new-2.tcl?category=[ns_urlencode $category]\">$category</a>\n"
}

if { $counter == 0 } {
    ns_write "no event categories are currently defined; you'll have to visit
<a href=\"categories.tcl\">the categories page</a> and define some."
}

ns_write "

</ul>

[ad_admin_footer]
"
 
