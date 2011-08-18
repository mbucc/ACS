# $Id: post-new.tcl,v 3.0 2000/02/06 03:36:20 ron Exp $
# File:     /calendar/admin/post-new.tcl
# Date:     1998-11-18
# Contact:  philg@mit.edu, ahmeds@arsdigita.com
# Purpose:  this page exists to solicit from the user what kind of an event
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set user_id [ad_get_user_id]

set_the_usual_form_variables 0
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)

ad_scope_error_check
set db [ns_db gethandle]
ad_scope_authorize $db $scope admin group_admin none

ReturnHeaders
ns_write "
[ad_scope_admin_header "Pick Category" $db]
[ad_scope_admin_page_title "Pick Category" $db]
[ad_scope_admin_context_bar [list "index.tcl?[export_url_scope_vars]" "Calendar"] "Pick Category"]

<hr>

<ul>
"
set counter 0
foreach category [database_to_tcl_list $db "
select category 
from calendar_categories 
where enabled_p = 't'
and [ad_scope_sql]"] {
    incr counter
    ns_write "<li><a href=\"post-new-2.tcl?[export_url_scope_vars]&category=[ns_urlencode $category]\">$category</a>\n"
}

if { $counter == 0 } {
    ns_write "no event categories are currently defined; you'll have to visit
<a href=\"categories.tcl?[export_url_scope_vars]\">the categories page</a> and define some."
}

ns_write "

</ul>

[ad_scope_admin_footer]
"
 
