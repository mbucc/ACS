# /www/bookmarks/delete-dead-links.tcl

ad_page_contract {
    deletes all occurrences of bookmarks with a dead url
    @param deleteable_link Dead link to delete
    @author David Hill (dh@arsdigita.com)
    @author Aurelius Prochazka (aure@arsdigita.com)
    @creation-date June 1999  
    @cvs-id delete-dead-links.tcl,v 3.2.2.9 2000/10/25 21:34:21 ashah Exp
} {
    deleteable_link:multiple
    {return_url:trim ""}
} 

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

# get the deleteable links from the form
if {![exists_and_not_null deleteable_link]} {
    ad_return_complaint 1 "You forgot to check off any links."
    return
} else {
    set i 0
    set bind_url_ids [list]
    foreach link $deleteable_link {
	lappend bind_url_ids ":url_id_$i"
	set "url_id_$i" $link
	incr i
    }
}

set sql_delete "
    delete from bm_list
    where owner_id = :user_id
    and url_id in ([join $bind_url_ids ","])"

# Note: This may break with a huge deleteable_link list, but it is somewhat
# unlikely that someone will have that many dead links and even more unlikely
# that they will check that many checkboxes on the previous page 

if [catch {db_dml unused $sql_delete} errmsg] {
    doc_return  200 text/html "<title>Error</title>
    <h1>Error</h1>
    <hr>
    We encountered an error while trying to process this DELETE:
    <pre>$errmsg</pre>
    [bm_footer]
    "
    return
}

# release the database handle
db_release_unused_handles 

ad_returnredirect $return_url
