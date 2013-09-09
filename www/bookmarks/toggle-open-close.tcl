# /www/bookmarks/toggle-open-close.tcl

ad_page_contract {

    Opens or closes folders in the bookmarks system
    @param bookmark_id the ID for the bookmark to be toggled
    @param action open or close   
    @author David Hill (dh@arsdigita.com)
    @author Aurelius Prochazka (aure@arsdigita.com)
    @created June 1999
    @cvs-id  toggle-open-close.tcl,v 3.3.6.5 2000/07/21 03:59:00 ron Exp
} {
    {bookmark_id:integer ""}
    {action ""}
}

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

# Note, we do not do error checking for this script because anybody messing with 
# the arguments in the url won't be able to do much, we have the owner_id=$user_id
# check in each of the sql updates instead, so instead of doing extra checks at 
# the top of this script, we have additional constraints in the sql, which we 
# think is better.

db_transaction {

    if { [string compare $action "open_all"] == 0 } {
	db_dml bm_update_1 "update bm_list set closed_p = 'f' where owner_id = :user_id"
    } elseif { [string compare $action "close_all"] == 0 } {
	db_dml bm_update_2 "update bm_list set closed_p = 't' where owner_id = :user_id"
    } else {
	# determine current state of folder (closed/open)

	set closed_p [db_string unused "select closed_p from bm_list where bookmark_id = :bookmark_id"]
    
	if { $closed_p == "t" } {
	    db_dml bm_update_closed "
	    update bm_list
            set    closed_p = 'f'
            where  bookmark_id = :bookmark_id 
	    and    owner_id    = :user_id"
	} else {
	    db_dml bm_update_open "
	    update bm_list
            set    closed_p = 't'
            where  bookmark_id = :bookmark_id 
	    and    owner_id    = :user_id"
	}
    }
}

# set the in_closed_p flag for items in the folder
bm_set_in_closed_p $user_id

db_release_unused_handles

ad_returnredirect ""
