# /www/bookmarks/insert-one-2.tcl

ad_page_contract {
    inserts a single bookmark into the bookmark system.
    Details: 
    1 splits the 'complete_url' to get the 'host_url'
    2 checks if 'complete_url' and implicitly 'host_url' are  already in bm_urls            if not,  inserts them into the table 
    3 inserts the corresponding 'pretty_title', 'bookmark_id', 'parent_id' (along with user_id)  into bm_list

    @param parent_id ID of parent bookmark
    @param complete_url the complete url for bookmark
    @param local_title Title 
    @param bookmark_id ID for bookmark
    @param return_url URL for user to return to
    @author David Hill (dh@arsdigita.com)
    @author Aurelius Prochazka (aure@arsdigita.com)
    @creation-date June 1999  
    @cvs-id insert-one-2.tcl,v 3.2.6.9 2001/01/09 22:53:06 khy Exp
} {
    parent_id:integer
    complete_url:trim
    local_title:trim
    bookmark_id:verify,integer,notnull
    return_url:trim
} 

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

# split the url to get the host_url
set host_url [bm_host_url $complete_url]

# check if the 'complete_url' is already in bm_urls
set count_urls "
    select count(*)
    from   bm_urls
    where  complete_url = :complete_url "

set n_complete_urls [db_string count_url $count_urls]

# if this url isn't already in the database, get the next 'url_id' and insert the url (complete and host)
# with it.
# if it is already in the database just get the corresponding 'url_id' 

if {$n_complete_urls == "0"} {
   
    db_transaction {
	set url_id [db_string new_bm_id "select bm_url_id_seq.nextval 
                                         from   dual"]
	
	db_dml url_insert "
        insert  into  bm_urls
        (url_id, host_url, complete_url)
        values
        (:url_id, :host_url, :complete_url) "
    }

} else {

    set url_id [db_string new_url_id "select url_id 
                                      from   bm_urls 
                                      where  complete_url= :complete_url"]

}

db_transaction {
    set insert_sql "
    insert into bm_list
    (bookmark_id, owner_id, url_id, local_title, parent_id, creation_date)
    values
    (:bookmark_id, :user_id, :url_id, :local_title, :parent_id, sysdate)"

    if [catch {db_dml url $insert_sql} errmsg] {
    # check and see if this was a double click
	set dbclick_p [db_string dbclick "select count(*) 
                                          from   bm_list 
	                                  where  bookmark_id = :bookmark_id"]
	
	if {$dbclick_p == "1"} {   
	    ad_returnredirect $return_url
	    return
	} else {
	    ad_return_complaint 1 "<li> There was an error making this insert into the database. $errmsg"
	    return 
	}
    }

}

db_release_unused_handles

ad_returnredirect $return_url











