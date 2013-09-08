
ad_page_contract {
    @param group_id Id of the group to remove user from
    @param user_id User ID to remove
    @param role role of the user
    @param return_url:optional the URL to send the user back to

    @cvs-id member-remove-2.tcl,v 3.2.6.4 2000/07/22 07:25:26 ryanlee Exp
} {
    group_id:notnull,naturalnum
    user_id:notnull,naturalnum
    role:notnull
    {return_url "group?[export_url_vars group_id]"}
}



db_dml delte_user_group_association "
    delete from 
        user_group_map 
    where
        user_id = :user_id and 
        group_id = :group_id and
        role = :role"

ad_returnredirect $return_url

