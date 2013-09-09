# /www/chat/js-chat.tcl

ad_page_contract {

    Chat using JavaScript
    If page is accessed through /groups pages then group_id and group_vars_set 
    are already set up in the environment by the ug_serve_section. group_vars_set 
    contains group related variables (group_id, group_name, group_short_name, 
    group_admin_email, group_public_url, group_admin_url, group_public_root_url,
    group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

    @author Aure (aure@arsdigita.com)
    @author Philip Greenspun (philg@mit.edu)
    @author Sarah Ahmeds (ahmeds@arsdigita.com)
    @param chat_room_id
    @param scope
    @param owner_id
    @param group_id
    @param on_what_id
    @creation-date 1998-11-18
    @cvs-id js-chat.tcl,v 3.2.6.7 2000/09/22 01:37:10 kevin Exp
} {
    {chat_room_id:naturalnum,notnull}
    {scope "public"}
    {owner_id:naturalnum,optional}
    {group_id:naturalnum,optional}
    {on_what_id:naturalnum,optional}
    
}
ad_scope_error_check

ad_scope_authorize $scope registered group_member none

set user_id [ad_verify_and_get_user_id]

ad_maybe_redirect_for_registration

set selection [db_0or1row chat_js_chat_get_pretty_name {select pretty_name, 
                                  group_id as private_group_id, 
                                  moderated_p 
                           from   chat_rooms 
                           where  chat_room_id=:chat_room_id}]

if { $selection == 0} {
    ad_scope_return_error "Room deleted" "We couldn't find chat room $chat_room_id.  
                                          It was probably deleted by the site administrator."
    return -code return
}


if {[empty_string_p $private_group_id] || [ad_user_group_member $private_group_id $user_id]} {

    doc_return  200 text/html "
	<html>
	<head>
	<title>[chat_system_name]: $pretty_name</title>
	</head>
	<frameset rows=\"100,*,0\" frameborder=no framespacing=5>
	<frame name=formpage marginwidth=10 marginheight=0  src=\"js-form.tcl?[export_url_scope_vars chat_room_id]\">
	<frame name=chat_rows marginwidth=10 marginheight=0 src=\"js-chat-rows.tcl?[export_url_scope_vars chat_room_id]#most_recent\">
	<frame name=refresh marginwidth=0 marginheight=0 src=\"js-refresh.tcl?[export_url_scope_vars chat_room_id]\">
	</frameset>
	<noframes>
	<html>
	<body bgcolor=yellow>
	This version of chat requires a modern browser.
	</body>
	</html>"
} else {
    db_release_unused_handles
    ad_returnredirect index.tcl?[export_url_scope_vars]
}









