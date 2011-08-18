# /chat/index.tcl
#
# by aure@arsdigita.com, April 1999
# 
# modified by philg@mit.edu, ahmeds@arsdigita.com
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set 
#       are already set up in the environment by the ug_serve_section. group_vars_set 
#       contains group related variables (group_id, group_name, group_short_name, 
#       group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and 
#       group_navbar_list)
#
# $Id: index.tcl,v 3.4.2.1 2000/03/30 12:36:18 carsten Exp $

# this command should be replaced ad_page_variables but it can't because
# ad_scope depends on existence of variables
set_the_usual_form_variables 0

# maybe scope, maybe scope related variables (owner_id, group_id, on_which_group, on_what_id)
# note that owner_id is the user_id of the user who owns this module (when scope=user)

ad_scope_error_check

set db [ns_db gethandle]
set user_id [ad_scope_authorize $db $scope registered group_member none]

set title [chat_system_name]

set page_content "[ad_scope_header $title $db]"

if { $scope == "public" } {

    append page_content "
    [ad_decorate_top "<h2>$title</h2>
    [ad_scope_context_bar_ws $title]" [ad_parameter DefaultDecoration chat]]"

} else {

    append page_content "
    [ad_scope_page_title $title $db]
    [ad_scope_context_bar_ws_or_index "Chat"]"

}

append page_content "
<hr>
<ul>
<li> Join current room:<ul>"

set room_query "
select unique pretty_name, 
       chat_room_id 
from   chat_rooms
where  active_p = 't'
and    (group_id is null or ad_group_member_p($user_id, group_id) = 't')
and    [ad_scope_sql chat_rooms] 
order by pretty_name"

set selection [ns_db select $db $room_query]

set room_list ""

while { [ns_db getrow $db $selection] } {
    set_variables_after_query 
    append room_list  "
    <li><a href=enter-room?[export_url_scope_vars chat_room_id]>$pretty_name</a>"
}

if {[empty_string_p $room_list]} {
    set room_list "No rooms available"
}

append page_content "
$room_list
</ul>"

if [ad_parameter UsersCanCreateRoomsP chat] {
    append page_content "<p>
    <li> <a href=create-room?[export_url_scope_vars]>Create a new room</a>"
}

append page_content "
</ul>
[ad_scope_footer]"

# release the database handle
ns_db releasehandle $db

# serve the page
ns_return 200 text/html $page_content


