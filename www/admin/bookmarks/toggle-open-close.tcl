# /www/admin/bookmarks/toggle-open-close.tcl

ad_page_contract {
    Opens or closes folders in the bookmarks system
    
    @param bookmark_id ID of the folder to open or close  
    @author  dh@arsdigita.com 
    @author  aure@arsdigita.com
    @created June 1999
    @cvs-id  toggle-open-close.tcl,v 3.3.2.5 2000/07/21 03:56:07 ron Exp
} {
    {bookmark_id:integer}
}

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration 

# note, we do no error checking for this script because anybody messing with 
# the arguments in the url won't be able to do much.  Besides, this is in the admin directory.

set owner_id  [db_string owner_id "select owner_id 
                                   from   bm_list 
                                   where  bookmark_id = :bookmark_id"]

db_transaction {

    # determine current state of folder ( closed/open )
    set closed_p [db_string status {
	select closed_p 
	from   bm_list 
	where  bookmark_id = :bookmark_id
    }]

    if { $closed_p=="t" } {
	# open the folder
	db_dml folder_open {
	    update bm_list
	    set    closed_p = 'f'
	    where  bookmark_id = :bookmark_id
	    and    owner_id = :owner_id
	}
    } else {
	# close the folder
	db_dml folder_close {
	    update bm_list
	    set    closed_p = 't'
	    where  bookmark_id = :bookmark_id
	    and    owner_id = :owner_id
	}
    }

    # set the in_closed_p flag for items in the folder
    bm_set_in_closed_p $owner_id
}

db_release_unused_handles

# send the browser back to the one-user page 
ad_returnredirect one-user?owner_id=$owner_id
    

