# $Id: spam-approve.tcl,v 3.0.4.1 2000/04/28 15:10:59 carsten Exp $
# File:     /groups/admin/group/spam-approve.tcl
# Date:     Mon Jan 17 13:39:51 EST 2000
# Contact:  ahmeds@mit.edu
# Purpose:  sends one spam provided it is approved by the administrator
#
# Note: group_id and group_vars_set are already set up in the environment by the ug_serve_section.
#       group_vars_set contains group related variables (group_id, group_name, group_short_name,
#       group_admin_email, group_public_url, group_admin_url, group_public_root_url, group_admin_root_url, 
#       group_type_url_p, group_context_bar_list and group_navbar_list)

set_the_usual_form_variables
# spam_id approved_p

set db [ns_db gethandle]

if { [ad_user_group_authorized_admin  [ad_verify_and_get_user_id]  $group_id $db] != 1 } {
    ad_return_error "Not Authorized" "You are not authorized to see this page"
    return
}

set counter [database_to_tcl_string  $db "select count(*)
from group_spam_history 
where spam_id = $spam_id"]

if { $counter == 0} {
    ad_return_complaint 1 "<li>No spam with spam id $spam_id was found in the database."
    return
} 

ns_db dml $db "update group_spam_history
               set approved_p ='$approved_p'
               where spam_id = $spam_id"

ns_db releasehandle $db
ad_returnredirect spam-index.tcl

if { $approved_p == "t" } {
    # although send_one_group_spam_message will not send disapproved messages , 
    # still no need to go through the unnecessary checking, so the proc here is
    # only called for approved messages
 
    ns_conn close
    
    ns_log Notice "groups/admin/group/spam-approve.tcl:  sending group spam $spam_id"
    send_one_group_spam_message $spam_id
    ns_log Notice "groups/admin/group/spam-approve.tcl: group spam $spam_id sent"
}

