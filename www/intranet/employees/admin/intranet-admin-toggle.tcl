# /www/intranet/employees/admin/intranet-admin-toggle.tcl

nsv_set apm_reload_watch "tcl/intranet-defs.tcl" 1

ad_page_contract {

    Toggles a user's intranet administration privileges   

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date Sun May 21 23:11:34 2000
    @cvs-id intranet-admin-toggle.tcl,v 3.3.2.6 2000/10/26 19:50:04 mbryzek Exp
    @param user_id The user ID
    @param return_url Optional The url to return to
} {
    user_id 
    { return_url "" }
}


set role "administrator"

set group_id [ad_administration_group_id [ad_parameter IntranetGroupType intranet] ""]
if { [im_user_intranet_admin_p $user_id] } {
    # They're already an admin - remove them from the group!
    db_dml delete_admin "delete from user_group_map where user_id=:user_id and group_id=:group_id and role=:role"
} else {
    # Add them as an admin
    ad_user_group_user_add $user_id $role $group_id
}

if { [empty_string_p $return_url] } {
    ad_returnredirect view?[export_url_vars user_id]
} else {
    ad_returnredirect $return_url
}


