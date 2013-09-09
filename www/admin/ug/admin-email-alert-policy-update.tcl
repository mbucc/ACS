ad_page_contract {
    Toggle the flag which sends email to admin when a user applies for group membership.
 
    @param group_id the id of the group to perform the action on 

    @cvs-id admin-email-alert-policy-update.tcl,v 3.2.2.3 2000/07/21 03:58:11 ron Exp
} {
    group_id:notnull,naturalnum
}


db_dml update_email_alert "update user_groups set email_alert_p = logical_negation(email_alert_p) where group_id = :group_id"

ad_returnredirect "group?[export_url_vars group_id]"
