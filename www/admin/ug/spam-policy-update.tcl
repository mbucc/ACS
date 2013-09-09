ad_page_contract {
    @param group_id the ID of the group
    @spam_policy the new SPAM policy

    @cvs-id spam-policy-update.tcl,v 3.2.2.4 2000/07/21 03:58:21 ron Exp
} {
    group_id:notnull,naturalnum
    spam_policy:notnull
}



db_dml update_ug_spam_policy "
update user_groups 
set spam_policy = :spam_policy 
where group_id = :group_id"
db_release_unused_handles
ad_returnredirect "group?[export_url_vars group_id]"