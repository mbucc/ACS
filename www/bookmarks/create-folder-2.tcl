# /www/bookmarks/create-folder-2.tcl

ad_page_contract {
    create a folder to store bookmarks in
    @param return_url the url to return to
    @param local_title title for url
    @param parent_id ID of parent folder 
    @param bookmark_id ID of bookmark
    @author David Hill (dh@arsdigita.com)
    @author Aurelius Prochazka (aure@arsdigita.com)
    @creation-date June 1999  
    @cvs-id create-folder-2.tcl,v 3.3.6.8 2001/01/09 22:46:00 khy Exp
} {
    local_title
    parent_id
    bookmark_id:verify,notnull,naturalnum
    return_url
} 

set user_id [ad_verify_and_get_user_id]
if { $user_id == 0 } {
    ad_returnredirect "/register/index?return_url=[ns_urlencode [ns_conn url]]"
    return
}

if {![info exists parent_id]} {
    set parent_id [db_null]
}

if {[empty_string_p $local_title]} {
    set local_title "unnamed"
}

set folder_p "t"
set closed_p "f"

db_transaction {

    set insert_sql "insert into bm_list
                           (bookmark_id, 
                            owner_id, 
                            local_title, 
                            parent_id, 
                            creation_date, 
                            folder_p, 
                            closed_p)
                    values
                            (:bookmark_id, 
                             :user_id, 
                             :local_title, 
                             :parent_id, 
                              sysdate, 
                             :folder_p, 
                             :closed_p)"

 # check and see if this was a double click
    set dbclick_p [db_string dbclick "select count(*) 
                                      from   bm_list 
                                      where bookmark_id=:bookmark_id"]
    if {$dbclick_p == "1"} {
	ad_returnredirect $return_url
	return
    }

    if [catch {db_dml unused $insert_sql} errmsg] {
	    ad_return_complaint 1 "<li> There was an error making this insert into the database. 
	<pre>$errmsg"
	    return 
    }

    bm_set_hidden_p $user_id
    bm_set_in_closed_p $user_id

}

# release the database handle
db_release_unused_handles 

ad_returnredirect $return_url







