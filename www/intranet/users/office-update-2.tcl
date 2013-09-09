# /www/intranet/users/office-update-2.tcl

ad_page_contract {
    Purpose: Saves users' office selections

    @param group_id
    @param return_url

    @author mbryzek@arsdigita.com
    @creation-date 4/4/2000

    @cvs-id office-update-2.tcl,v 3.2.6.7 2000/08/23 00:47:09 mbryzek Exp
} {
    { group_id:multiple,naturalnum "" }
    { return_url "" }
}

# We've already validated the user id with a filter
set user_id [ad_get_user_id]

db_transaction {
    # Clear out the old office preferences if they exist
    set office_group_id [im_office_group_id]
    db_dml clear_old_pref "delete from user_group_map 
                            where user_id=:user_id 
                              and group_id in (select group_id 
                                                 from user_groups 
                                                where parent_group_id=:office_group_id)" 
    # Add the user to all checked groups
    foreach id $group_id {
	ad_user_group_user_add $user_id member $id 
    }
} on_error {
    ad_return_error "Database Error" "An error occured while we attempted to add you to the selected offices:
<pre>
$errmsg
</pre>"
    return
}

db_release_unused_handles

if { [empty_string_p $return_url] } {
    set return_url view?[export_url_vars user_id]
}
ad_returnredirect $return_url
