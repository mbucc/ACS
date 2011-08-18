# $Id: spam-policy-update.tcl,v 3.0.4.1 2000/04/28 15:10:59 carsten Exp $
# File:    /groups/admin/group/spam-policy-update.tcl
# Date:    mid-1998
# Contact: ahmeds@mit.edu
# Purpose: sets the spam policy for the group
#
# Note: group_id and group_vars_set are already set up in the environment by the ug_serve_section.
#       group_vars_set contains group related variables (group_id, group_name, group_short_name,
#       group_admin_email, group_public_url, group_admin_url, group_public_root_url, group_admin_root_url, 
#       group_type_url_p, group_context_bar_list and group_navbar_list)

set_form_variables
# spam_policy

set db [ns_db gethandle]


if { [ad_user_group_authorized_admin [ad_verify_and_get_user_id] $group_id $db] != 1 } {
    ad_return_error "Not Authorized" "You are not authorized to see this page"
    return
}

ns_db dml $db "
update user_groups 
set spam_policy = '$spam_policy' 
where group_id = $group_id"

if { $spam_policy == "open" } {
    # grant every spam of this group waiting in the queue 
   
    ns_db dml $db "update group_spam_history
                   set approved_p ='t'
                   where group_id = $group_id
                   and approved_p is null"

    
    ns_db releasehandle $db
    ad_returnredirect spam-index.tcl
    
    ns_conn close
    
    ns_log Notice "/groups/admin/group/spam-policy-update.tcl:  sending all waiting spam for group $group_id"
    send_all_group_spam_messages $group_id
    ns_log Notice "/groups/admin/group/spam-policy-update.tcl:  sent all waiting spam for group $group_id"
    
} else {
    #spam_policy = wait / closed
    
    ad_returnredirect spam-index.tcl
}


