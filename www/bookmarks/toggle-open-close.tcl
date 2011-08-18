# /bookmarks/toggle-open-close.tcl
#
# opens or closes folders in the bookmarks system
#
# dh@arsdigita.com and aure@arsdigita.com, June 1999
#
# $Id: toggle-open-close.tcl,v 3.0.4.3 2000/04/28 15:09:47 carsten Exp $

ad_page_variables {
    {bookmark_id ""}
    {action ""}
}
 
set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

# note, we do not do error checking for this script because anybody messing with 
# the arguments in the url won't be able to do much, we have the owner_id=$user_id
# check in each of the sql updates instead, so instead of doing extra checks at 
# the top of this script, we have additional constraints in the sql, which we 
# think is better.

set db [ns_db gethandle]

ns_db dml $db "begin transaction"


if { [string compare $action "open_all"] == 0 } {
    ns_db dml $db "update bm_list set closed_p = 'f' where owner_id = $user_id"
} elseif { [string compare $action "close_all"] == 0 } {
    ns_db dml $db "update bm_list set closed_p = 't' where owner_id = $user_id"
} else {
    # determine current state of folder (closed/open)

    set closed_p [database_to_tcl_string $db "
	select closed_p from bm_list where bookmark_id = $bookmark_id"]
    
    if { $closed_p == "t" } {
	ns_db dml $db "
	    update bm_list
            set    closed_p = 'f'
            where  bookmark_id = $bookmark_id and owner_id = $user_id"
    } else {
	ns_db dml $db "
	    update bm_list
            set    closed_p = 't'
            where  bookmark_id = $bookmark_id and owner_id = $user_id"
    }
}

bm_set_in_closed_p $db $user_id

ns_db dml $db "end transaction"

ad_returnredirect ""
