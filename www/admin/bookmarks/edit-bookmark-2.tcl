# /www/admin/bookmarks/edit-bookmark-2.tcl

ad_page_contract {
    admin version
    edit a bookmark in your bookmark list
    @param bookmark_id 
    @param local_title
    @param complete_url
    @param parent_id
    @author David Hill (dh@arsdigita.com)
    @author Aurelius Prochazka (aure@arsdigita.com)
    @creation-date June 1999  
    @cvs-id edit-bookmark-2.tcl,v 3.2.2.5 2000/07/21 03:56:06 ron Exp
} {
    bookmark_id:integer
    local_title:trim
    complete_url:optional
    private_p
    parent_id:integer
} 
# 

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

# --error-checking ---------------------------
set exception_text ""
set exception_count 0

if {(![info exists bookmark_id])||([empty_string_p $bookmark_id])} {
    incr exception_count
    append exception_text "<li>No bookmark was specified"
}

# return errors
if { $exception_count> 0 } {
    ad_return_complaint $exception_count $exception_text
    return 0
}

# ---------------------------------------------

if { ![info exists parent_id] || [empty_string_p $parent_id] } {
    set parent_id "null"
}

set owner_id [db_string owner_id "select owner_id 
                                  from   bm_list 
                                  where  bookmark_id = :bookmark_id"]
db_transaction {

    # if the bookmark to edit is a folder, complete_url won't be defined
    if {![info exists complete_url]} {
	# this is a folder so edit its name	

	set sql_update "
	 update  bm_list
         set     local_title = :local_title,
                 private_p = :private_p,
                 parent_id = :parent_id
         where   owner_id = :owner_id
         and     bookmark_id = :bookmark_id"

	db_dml bm_update $sql_update 
   
    } else {
	# entry is a bookmark - need to update both name and url
	
	set host_url [bm_host_url $complete_url]
	
	# check to see if we already have the url in our database
	set url_id [db_string url "select url_id 
                               from   bm_urls 
                               where  complete_url = :complete_url"]
	
	if {[empty_string_p $url_id]} {
	    # we don't have the url - insert the url into the database
	    set url_id [db_string unused "select bm_url_id_seq.nextval from dual"]
	    db_dml url_insert {    
		insert into bm_urls 
		(url_id, host_url, complete_url)
		values
		(:url_id, :host_url, :complete_url)
	    }
	}
                    
	# have added the url if needed - now update the name 
	set update_sql {
	    update  bm_list
	    set     local_title = :local_title,
            url_id = :url_id,
            private_p = :private_p,
            parent_id = :parent_id
	    where   bookmark_id = :bookmark_id
	}

    db_dml url_update $update_sql
}

# propagate our changes (closed / hidden)
bm_set_hidden_p $owner_id
bm_set_in_closed_p $owner_id

} on_error {
    ad_return_complaint 1 "Error in transction: $errmsg"    
}

# release the database handle
db_release_unused_handles 

# send the user back to where they came from before editing began
ad_returnredirect one-user.tcl?owner_id=$owner_id



















































