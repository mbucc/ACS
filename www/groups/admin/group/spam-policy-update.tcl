# File:    /groups/admin/group/spam-policy-update.tcl
ad_page_contract {
    @param spam_policy the new spam policy

 Purpose: sets the spam policy for the group

 Note: group_id and group_vars_set are already set up in the environment by the ug_serve_section.
       group_vars_set contains group related variables (group_id, group_name, group_short_name,
       group_admin_email, group_public_url, group_admin_url, group_public_root_url, group_admin_root_url, 
       group_type_url_p, group_context_bar_list and group_navbar_list)
    @cvs-id spam-policy-update.tcl,v 3.3.2.4 2000/07/24 19:14:52 ryanlee Exp
} {
    spam_policy:notnull
}

if { [ad_user_group_authorized_admin [ad_verify_and_get_user_id] $group_id] != 1 } {
    ad_return_error "Not Authorized" "You are not authorized to see this page"
    return
}

db_dml update_ug_spam_policy "
update user_groups 
set spam_policy = :spam_policy 
where group_id = :group_id"

if { $spam_policy == "open" } {
    # grant every spam of this group waiting in the queue 
   
    db_dml update_all_queued_spam "update group_spam_history
                   set approved_p ='t'
                   where group_id = :group_id
                   and approved_p is null"

    
    db_release_unused_handles
    ad_returnredirect spam-index
    
    ns_conn close
    
    ns_log Notice "/groups/admin/group/spam-policy-update:  sending all waiting spam for group $group_id"
    send_all_group_spam_messages $group_id
    ns_log Notice "/groups/admin/group/spam-policy-update:  sent all waiting spam for group $group_id"
    
} else {
    #spam_policy = wait / closed
    
    ad_returnredirect spam-index
}






