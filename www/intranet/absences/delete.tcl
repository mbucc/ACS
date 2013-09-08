# /www/intranet/absences/delete.tcl

ad_page_contract {
    created, jsalz@mit.edu, 28 Feb 2000
    Purpose: Deletes a vacation for a specified user

    @param vacation_id:integer 
    @param return_url 
    @author Jon Salz (jsalz@mit.edu)
    @creation-date 28 Feb 2000
    @cvs-id delete.tcl,v 1.3.2.9 2000/08/16 21:24:32 mbryzek Exp
} {
    vacation_id:notnull,naturalnum
    { return_url "index" }
}

set my_user_id [ad_maybe_redirect_for_registration]



set user_id [db_string user_id_from_vacation "
    select user_id
    from user_vacations 
    where vacation_id = :vacation_id
" -default ""]

# handle double delete click
if ![exists_and_not_null user_id] {
   ad_returnredirect $return_url
   return
}

if { $user_id == $my_user_id || [im_is_user_site_wide_or_intranet_admin $my_user_id] } {
    
    db_dml vacation_delete "delete from user_vacations where vacation_id = :vacation_id"
    # Only do this if calendar package is enabled
    if [apm_package_enabled_p "calendar"] {
	cal_delete_mapped_instances "user_vacations" $vacation_id
    }
    db_release_unused_handles
    ad_returnredirect $return_url
    return
}
db_release_unused_handles
ad_return_warning "Not authorized" "You are not authorized to perform this operation."


