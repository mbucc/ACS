# /www/bookmarks/delete-bookmark-2.tcl

ad_page_contract {
    actually deletes a bookmark
    @param bookmark_id ID for bookmark to be deleted
    @param return_url url for user to return to
    @author David Hill (dh@arsdigita.com)
    @author Aurelius Prochazka (aure@arsdigita.com)
    @creation-date June 1999  
    @cvs-id delete-bookmark-2.tcl,v 3.1.6.7 2000/07/21 03:58:58 ron Exp
} {
    bookmark_id
    return_url
} 

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

# start error-checking
set exception_text ""
set exception_count 0

if { ![info exists bookmark_id] || [empty_string_p $bookmark_id] } {
    incr exception_count
    append exception_text "<li>No bookmark was specified"
}

# make sure that the user owns the bookmark

set ownership_test [db_string ownership "
select count(*)
from   bm_list
where  owner_id = :user_id
and bookmark_id = :bookmark_id"]

if {$ownership_test == 0} {
    incr exception_count
    append exception_text "<li>You cannot edit this bookmark"
}

# return errors
if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return 0
}

db_transaction {
    db_dml child_delete "
    delete from bm_list 
    where  bookmark_id in (select     bookmark_id
                           from       bm_list
			   connect by prior bookmark_id = parent_id
			   start with parent_id = :bookmark_id)"

    db_dml parent_delete "delete from bm_list where bookmark_id = :bookmark_id"
} on_error {
    ad_return_error "Ouch!" "The database chocked on our delete:
    <blockquote>
    <pre>
    $errmsg
    </pre>
    </blockquote>
    "
    return
}
 
# release the database handle
db_release_unused_handles 

# send the browser back to the url it was at before the editing process began
ad_returnredirect $return_url

