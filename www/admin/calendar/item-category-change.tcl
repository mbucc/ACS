# $Id: item-category-change.tcl,v 3.0.4.1 2000/04/28 15:08:26 carsten Exp $
if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set user_id [ad_get_user_id]
if { $user_id == 0 } {
    ad_returnredirect "/register/index.tcl?return_url=[ns_urlencode [ns_conn url]?category=$category]"
    return
}

set_form_variables 

#calendar_id

set db [ns_db gethandle]

set title [database_to_tcl_string $db "select title from calendar
where calendar_id = $calendar_id"]

ReturnHeaders
ns_write "[ad_admin_header "Pick New Category for $title"]
<h2>Pick new category</h2>
for <a href=\"item.tcl?calendar_id=$calendar_id\">$title</a>
<hr>

<ul>
"

set counter 0
foreach category [database_to_tcl_list $db "select category from calendar_categories where enabled_p = 't'"] {
    incr counter
    ns_write "<li><a href=\"item-category-change-2.tcl?[export_url_vars category calendar_id]\">$category</a>\n"
}

ns_write "

</ul>

[ad_admin_footer]
"
 
