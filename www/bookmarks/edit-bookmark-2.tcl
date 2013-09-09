# /www/bookmarks/edit-bookmark-2.tcl

ad_page_contract {
    edit a bookmark in your bookmark list
    @param local_title Title for bookmark
    @param complete_url URL 
    @param bookmark_id ID for bookmark 
    @param parent_id ID of the parent bookmark
    @param private_p permission
    @param return_url URL for user to return to
    @author David Hill (dh@arsdigita.com)
    @author Aurelius Prochazka (aure@arsdigita.com)
    @creation-date June 1999  
    @cvs-id edit-bookmark-2.tcl,v 3.2.2.10 2000/07/24 22:40:39 tina Exp
} {
    local_title:trim,notnull 
    {complete_url ""}
    bookmark_id:integer,notnull 
    parent_id:integer
    private_p:trim
    return_url:trim
} 

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

# start error-checking
# make sure that the user owns the bookmark
set  ownership_query "
        select count(*)
        from   bm_list
        where  owner_id = :user_id
        and bookmark_id = :bookmark_id"

set ownership_test [db_string ownership $ownership_query]

page_validation { 
    if {$ownership_test==0} {
	error "You can not edit this bookmark"
	return
    }

    set folder_p [db_string folder_p "
	select folder_p 
	from   bm_list 
	where  bookmark_id = :bookmark_id" -default ""] 


    if { $folder_p == "f" && [empty_string_p $complete_url]} {
	error "You need to provide a URL"
	return				  
     }
     
     # with a url, validate it 
     if { $folder_p == "f" } { 
	 if { ![regexp {^[^:\"]+://} $complete_url] } {
	     set complete_url "http://$complete_url"
	 }

	 if {[catch {ns_httpget $complete_url 10} url_content]} {
	     error "
	     We're sorry but we can not detect a title for this bookmark,
	     the URL is unreachable. <p> If you still want to add this bookmark now,
	     press \[Back\] on your browser and check the URL or type in a title.
	     "
	     return
	 }
     }

}

if { ![info exists parent_id] || [empty_string_p $parent_id] } {
    set parent_id [db_null]
}
 
db_transaction {

    #  if the bookmark to edit is a folder, complete_url won't be defined
    if [empty_string_p $complete_url] {
 
	# this is a folder so edit its name
	db_dml bm_update "
         update  bm_list
         set     local_title = :local_title,
                 private_p = :private_p,
                 parent_id = :parent_id
         where   owner_id = :user_id
         and     bookmark_id = :bookmark_id"

    } else {

	# entry is a bookmark - need to update both name and url

	set host_url [bm_host_url $complete_url]
    
	# check to see if we already have the url in our database
	set url_id [db_string url "
	select url_id
	from   bm_urls
	where  complete_url = :complete_url" -default ""]
	
	# if we don't have the url, then insert the url into the database
	if {[empty_string_p $url_id]} { 
	    set url_id [db_string url "select bm_url_id_seq.nextval from dual"]
	    db_dml url_insert "    
	    insert into bm_urls 
	    (url_id, host_url, complete_url)
	    values
	    (:url_id, :host_url, :complete_url)" 
	}
                    
	# have added the url if needed - now just update the name
	db_dml url_update "
        update  bm_list
        set     local_title = :local_title,
                url_id = :url_id,
                private_p = :private_p,
                parent_id = :parent_id
        where   bookmark_id = :bookmark_id"  
    }

    bm_set_hidden_p $user_id

    bm_set_in_closed_p $user_id
} on_error {
    ad_return_complaint 1 "Error in transction: $errmsg"    
}

# release the database handle before serving the page
db_release_unused_handles 

# send the user back to where they came from before editing began
ad_returnredirect $return_url








