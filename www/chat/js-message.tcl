# $Id: js-message.tcl,v 3.0 2000/02/06 03:36:46 ron Exp $
# File:     /chat/js-message.tcl
# Date:     1998-11-18
# Contact:  aure@arsdigita.com,philg@mit.edu, ahmeds@arsdigita.com

# Note: if page is accessed through /groups pages then group_id and group_vars_set 
#       are already set up in the environment by the ug_serve_section. group_vars_set 
#       contains group related variables (group_id, group_name, group_short_name, 
#       group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

set_the_usual_form_variables

# chatter_id
# maybe scope, maybe scope related variables (owner_id, group_id, on_which_group, on_what_id)
# note that owner_id is the user_id of the user who owns this module (when scope=user)

ad_scope_error_check

set db [ns_db gethandle]
set user_id [ad_scope_authorize $db $scope registered group_member none]

set pretty_name [database_to_tcl_string $db "select first_names||' '||last_name from users where user_id=$chatter_id"]
ns_log Notice "CHATTER: $pretty_name"
ns_db releasehandle $db

ReturnHeaders


if {[ad_parameter MostRecentOnTopP chat]} {
    ns_write "
    <html>
    <head>
    <title>Chat: $pretty_name</title>
    </head>
    <frameset rows=\"100,*,0\" frameborder=no border=0 framespacing=0>
    <frame name=form marginwidth=10 marginheight=0  src=\"js-message-form.tcl?[export_url_scope_vars chatter_id]\">
    <frame name=chat_rows marginwidth=10 marginheight=0 src=\"js-message-chat-rows.tcl?[export_url_scope_vars chatter_id]#most_recent\">
    <frame name=refresh marginwidth=0 marginheight=0 src=\"js-message-refresh.tcl?[export_url_scope_vars chatter_id]\">
    </frameset>
    <noframes>
    <html>
    <body bgcolor=yellow>
    This version of chat requires a modern browser.
    </body>
    </html>
    "
} else {
    ns_write "
    <html>
    <head>
    <title>Chat: $pretty_name</title>
    </head>
    <frameset rows=\"*,100,0\" frameborder=no border=0 framespacing=0>
    <frame name=chat_rows marginwidth=10 marginheight=0 src=\"js-message-chat-rows.tcl?[export_url_scope_vars chatter_id]#most_recent\">
    <frame name=form marginwidth=10 marginheight=0 src=\"js-message-form.tcl?[export_url_scope_vars chatter_id]\">
    <frame name=refresh marginwidth=0 marginheight=0 src=\"js-message-refresh.tcl?[export_url_scope_vars chatter_id]\">
    </frameset>
    <noframes>
    <html>
    <body bgcolor=yellow>
    This version of chat requires a modern browser.
    </body>
    </html>
    "
}
    

