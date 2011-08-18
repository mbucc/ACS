# /admin/bookmarks/toggle-open-close.tcl
#
# opens or closes folders in the bookmarks system
#
# by dh@arsdigita.com and aure@arsdigita.com, June 1999
#
# $Id: toggle-open-close.tcl,v 3.0.4.2 2000/04/28 15:08:25 carsten Exp $

ad_page_variables {bookmark_id}

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration 

# note, we do no error checking for this script because anybody messing with 
# the arguments in the url won't be able to do much.  Besides, this is in the admin directory.

# get database handle
set db [ns_db gethandle]

set owner_id  [database_to_tcl_string $db "
select owner_id from bm_list where bookmark_id = $bookmark_id"]

ns_db dml $db "begin transaction"

# determine current state of folder ( closed/open )
set closed_p [database_to_tcl_string $db "select closed_p from bm_list where bookmark_id=$bookmark_id"]

if { $closed_p=="t" } {
    # open the folder
    ns_db dml $db "
    update bm_list
    set    closed_p = 'f'
    where  bookmark_id = $bookmark_id
    and    owner_id = $owner_id"
} else {
    # close the folder
    ns_db dml $db "
    update bm_list
    set    closed_p = 't'
    where  bookmark_id = $bookmark_id
    and    owner_id = $owner_id"
}

# set the in_closed_p flag for items in the folder
bm_set_in_closed_p $db $owner_id

ns_db dml $db "end transaction"

# send the browser back to the one-user page 
ad_returnredirect one-user?owner_id=$owner_id
    


