

ad_page_contract {
    @param dont_spam_me_p don't spam me
    @param return_url the url to send the user back to

    @cvs-id edit-preference.tcl,v 3.2.6.4 2000/07/24 20:17:56 ryanlee Exp

 Note: group_id and group_vars_set are already set up in the environment by the ug_serve_section.
       group_vars_set contains group related variables (group_id, group_name, group_short_name,
       group_admin_email, group_public_url, group_admin_url, group_public_root_url, group_admin_root_url, 
       group_type_url_p, group_context_bar_list and group_navbar_list)
} {
    dont_spam_me_p:optional
    {return_url "spam-index"}
}

set user_id [ad_verify_and_get_user_id]

ad_scope_authorize $scope all group_member none

set counter [db_string  get_gmemail_count "
select count(*) 
from group_member_email_preferences
where group_id = :group_id
and user_id = :user_id "]

if { $counter == 0 } {
    db_dml insert_intogmemail_prefs "insert into group_member_email_preferences
    (group_id, user_id, dont_spam_me_p)
    values 
    (:group_id, :user_id, :dont_spam_me_p)"
} else {
    db_dml update_intogmemail_prefs "update group_member_email_preferences
    set dont_spam_me_p = :dont_spam_me_p
    where group_id=:group_id
    and user_id=:user_id"
}

db_release_unused_handles

ad_returnredirect $return_url
