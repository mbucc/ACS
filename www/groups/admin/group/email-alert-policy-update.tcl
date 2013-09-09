# /groups/admin/group/member-add.tcl

ad_page_contract {

    Toggle the flag which sends email to admin when a user applies for group membership.

 Note: group_id and group_vars_set are already set up in the environment by the ug_serve_section.
       group_vars_set contains group related variables (group_id, group_name, group_short_name,
       group_admin_email, group_public_url, group_admin_url, group_public_root_url, group_admin_root_url, 
       group_type_url_p, group_context_bar_list and group_navbar_list)
 
    @cvs-id email-alert-policy-update.tcl,v 3.2.2.5 2000/07/26 23:22:24 ryanlee Exp
} {
}

if { [ad_user_group_authorized_admin [ad_verify_and_get_user_id] $group_id] != 1 } {
    ad_return_error "Not Authorized" "You are not authorized to see this page"
    return
}

db_dml update_ug_email_alert_p "
update user_groups set email_alert_p = logical_negation(email_alert_p) where group_id = :group_id"

ad_returnredirect members

