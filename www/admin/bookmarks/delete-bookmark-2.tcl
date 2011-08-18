# $Id: delete-bookmark-2.tcl,v 3.0.4.1 2000/04/28 15:08:24 carsten Exp $
# delete-bookmark-2.tcl
# admin version
#
# carries out the delete function
#
# by aure@arsdigita.com and dh@arsdigita.com

set_the_usual_form_variables
# bookmark_id



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

set db [ns_db gethandle]

# get the owner for this bookmark
set owner_id [database_to_tcl_string $db "select owner_id from bm_list where bookmark_id=$bookmark_id"]


set sql_delete "
    delete from bm_list 
    where bookmark_id   in (select  bookmark_id
                        from    bm_list
                        connect by prior bookmark_id = parent_id
                        start with parent_id = $bookmark_id)
    or bookmark_id = $bookmark_id"

if [catch {ns_db dml $db $sql_delete} errmsg] {
    ns_return 200 text/html "<title>Error</title>
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


# send the browser back to the url it was at before the editing process began
ad_returnredirect one-user.tcl?owner_id=$owner_id










