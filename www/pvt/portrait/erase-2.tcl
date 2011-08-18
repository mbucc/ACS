# $Id: erase-2.tcl,v 3.0.4.1 2000/04/28 15:11:24 carsten Exp $
# 
# /pvt/portrait/erase-2.tcl
#
# by philg@mit.edu on September 26, 1999
#
# erase's a user's portrait (NULLs out columns in the database)
#
# the key here is to null out portrait_upload_date, which is 
# used by pages to determine portrait existence 
# 

ad_maybe_redirect_for_registration

set user_id [ad_verify_and_get_user_id]

set db [ns_db gethandle]

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

ad_returnredirect "/pvt/home.tcl"
