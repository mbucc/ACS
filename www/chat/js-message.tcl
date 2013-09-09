# /www/chat/js-message-form.tcl

ad_page_contract { 

    If page is accessed through /groups pages then group_id and group_vars_set 
    are already set up in the environment by the ug_serve_section. group_vars_set 
    contains group related variables (group_id, group_name, group_short_name, 
    group_admin_email, group_public_url, group_admin_url, group_public_root_url,
    group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)
    
    @author Aure (aure@arsdigita.com)
    @author Philip Greenspun (philg@mit.edu)
    @author Sarah Ahmeds (ahmeds@arsdigita.com)
    @param chatter_id
    @param scope
    @param owner_id
    @param group_id
    @param on_which_group
    @param on_what_id
    @creation-date 1998-11-18
    @cvs-id  js-message.tcl,v 3.0.12.5 2000/09/22 01:37:13 kevin Exp
} { 
    chatter_id:naturalnum,notnull
    scope:optional
    owner_id:naturalnum,optional
    group_id:naturalnum,optional
    on_which_group:naturalnum,optional
    on_what_id:naturalnum,optional
}

ad_scope_error_check

set user_id [ad_scope_authorize $scope registered group_member none]

set pretty_name [db_string chat_js_message_pretty_name "
                   select first_names||' '||last_name from users where user_id=$chatter_id"]
ns_log Notice "CHATTER: $pretty_name"


set page_content ""

if {[ad_parameter MostRecentOnTopP chat]} {
    append page_content "
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
    append page_content  "
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


doc_return  200 text/html $page_content


