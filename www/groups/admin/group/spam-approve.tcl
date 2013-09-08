# /groups/admin/group/spam-approve.tcl
ad_page_contract {
    @param spam_id the ID of the spam item
    @param approved_p is this thing approved


 Purpose:  sends one spam provided it is approved by the administrator

 Note: group_id and group_vars_set are already set up in the environment by the ug_serve_section.
       group_vars_set contains group related variables (group_id, group_name, group_short_name,
       group_admin_email, group_public_url, group_admin_url, group_public_root_url, group_admin_root_url, 
       group_type_url_p, group_context_bar_list and group_navbar_list)
    @cvs-id spam-approve.tcl,v 3.2.2.4 2000/07/24 19:11:58 ryanlee Exp

} {
    spam_id:notnull,naturalnum
    approved_p:notnull
}



if { [ad_user_group_authorized_admin  [ad_verify_and_get_user_id]  $group_id ] != 1 } {
    ad_return_error "Not Authorized" "You are not authorized to see this page"
    return
}

set counter [db_string get_count_gs "select count(*)
from group_spam_history 
where spam_id = :spam_id"]

if { $counter == 0} {
    ad_return_complaint 1 "<li>No spam with spam id $spam_id was found in the database."
    return
} 

db_dml update_and_approve_spam "update group_spam_history
               set approved_p =:approved_p
               where spam_id = :spam_id"

db_release_unused_handles
ad_returnredirect spam-index

if { $approved_p == "t" } {
    # although send_one_group_spam_message will not send disapproved messages , 
    # still no need to go through the unnecessary checking, so the proc here is
    # only called for approved messages
 
    ns_conn close
    
    ns_log Notice "groups/admin/group/spam-approve: sending group spam $spam_id"
    send_one_group_spam_message $spam_id
    ns_log Notice "groups/admin/group/spam-approve: group spam $spam_id sent"
}
