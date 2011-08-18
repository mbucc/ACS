# $Id: portrait-erase.tcl,v 3.0.4.1 2000/04/28 15:09:37 carsten Exp $
# 
# /admin/users/portrait-erase.tcl
#
# by philg@mit.edu on September 28, 1999 (his friggin' 36th birthday)
#
# erase's a user's portrait (NULLs out columns in the database)
#
# the key here is to null out portrait_upload_date, which is 
# used by pages to determine portrait existence 
# 

set_the_usual_form_variables

# user_id

ad_maybe_redirect_for_registration

set admin_user_id [ad_verify_and_get_user_id]

set db [ns_db gethandle]

if ![ad_administration_group_member $db "site_wide" "" $admin_user_id] {
    ad_return_error "Unauthorized" "You're not a member of the site-wide administration group"
    return
}


ns_db dml $db "update users
set portrait = NULL,
    portrait_comment = NULL,
    portrait_client_file_name = NULL,
    portrait_file_type = NULL,
    portrait_file_extension = NULL,
    portrait_original_width = NULL,
    portrait_original_height = NULL,
    portrait_upload_date = NULL
where user_id = $user_id"

ad_returnredirect "one.tcl?user_id=$user_id"
