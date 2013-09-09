# /www/chat/index.tcl

ad_page_contract {

    @author Aure (aure@arsdigita.com)
    @author Philip Greenspun (philg@mit.edu)
    @author Sarah Ahmeds (ahmeds@arsdigita.com)

    @creation-date April 1999
    @cvs-id index.tcl,v 3.6.2.8 2000/09/22 01:37:09 kevin Exp 

    @param owner_id is user_id of the user who owns this module (when scope=user)
} {
    {scope:optional}
    {owner_id:optional}
    {group_id:optional}
    {on_which_group:optional}
    {on_what_id:optional}
}

# note that owner_id is the 

ad_scope_error_check

set user_id [ad_scope_authorize $scope registered group_member none]

set title [chat_system_name]

set page_content "[ad_scope_header $title]"

if { $scope == "public" } {

    append page_content "
    [ad_decorate_top "<h2>$title</h2>
    [ad_scope_context_bar_ws $title]" [ad_parameter DefaultDecoration chat]]"

} else {

    append page_content "
    [ad_scope_page_title $title]
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
and    (group_id is null or ad_group_member_p(:user_id, group_id) = 't')
and    [ad_scope_sql chat_rooms] 
order by pretty_name"

set room_list ""

db_foreach chat_index_list_rooms $room_query {
    append room_list "
    <li><a href=enter-room?[export_url_scope_vars chat_room_id]>[ns_quotehtml $pretty_name]</a>"
} if_no_rows {
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


# serve the page
doc_return  200 text/html $page_content



















