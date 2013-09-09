# /www/admin/bookmarks/delete-bookmark-2.tcl

ad_page_contract {
    admin version
    carries out the delete function
    @param bookmark_id ID of bookmark to be deleted
    @author David Hill (dh@arsdigita.com)
    @author Aurelius Prochazka (aure@arsdigita.com)    
    @creation-date June 1999  
    @cvs-id delete-bookmark-2.tcl,v 3.2.2.5 2000/09/22 01:34:23 kevin Exp
} {
    {bookmark_id:integer}
} 

# --start error----------------------------------------
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

# -----------------------------------------------------
# get the owner for this bookmark
set owner_id [db_string owner "select owner_id 
                               from   bm_list 
                               where  bookmark_id = :bookmark_id"]

set sql_delete "
    delete from bm_list 
    where bookmark_id   in (select  bookmark_id
                        from    bm_list
                        connect by prior bookmark_id = parent_id
                        start with parent_id = :bookmark_id)
    or bookmark_id = :bookmark_id"

if [catch {db_dml bm_delete $sql_delete} errmsg] {
    doc_return  200 text/html "<title>Error</title>
    <h1>Error</h1>
    [ad_admin_contextbar [ad_admin_context_bar [list index.tcl Bookmarks] [list one-user.tcl?[export_url_vars owner_id] $owner_name's] [list edit-bookmark.tcl?[export_url_vars bookmark_id] Edit] Error]
    <hr>
    We encountered an error while trying to process this delete:
    <blockquote>
    <pre>
    $errmsg
    </pre>
    </blockquote>
    [ad_admin_footer]
    "
    return
}

# release the database handle
db_release_unused_handles 

# send the browser back to the url it was at before the editing process began
ad_returnredirect one-user.tcl?owner_id=$owner_id







