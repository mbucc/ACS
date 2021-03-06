# /chat/js-message-post-message.tcl

ad_page_contract { 

    Note: if page is accessed through /groups pages then group_id and group_vars_set 
    are already set up in the environment by the ug_serve_section. group_vars_set 
    contains group related variables (group_id, group_name, group_short_name, 
    group_admin_email, group_public_url, group_admin_url, group_public_root_url,
    group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)
    
    @author Aure (aure@arsdigita.com)
    @author Philip Greenspun (philg@mit.edu)
    @author Sarah Ahmeds (ahmeds@arsdigita.com)
    @param msg
    @param chatter_id
    @param scope  maybe scope, maybe scope related variables (owner_id, group_id, on_which_group, on_what_id)
    @param owner_id owner_id is the user_id of the user who owns this module (when scope=user)
    @param group_id
    @param on_which_group
    @param on_what_id
    @creation-date 1998-11-18
    @cvs-id js-message-post-message.tcl,v 3.2.2.4 2000/07/21 03:59:07 ron Exp
} { 
    msg:notnull
    chatter_id:naturalnum,notnull
    scope:optional
    owner_id:naturalnum,optional
    group_id:naturalnum,optional
    on_which_group:naturalnum,optional
    on_what_id:naturalnum,optional
}


ad_scope_error_check

set user_id [ad_scope_authorize $scope registered group_member none]

chat_post_personal_message $msg $user_id $chatter_id

db_release_unused_handles

ad_returnredirect js-message-chat-rows.tcl?[export_url_scope_vars chatter_id]&#most_recent

