# /www/admin/static/delete-page.tcl

ad_page_contract {

    Deletes a row from the static_pages table

    @author luke@arsdigita.com
    @creation-date Jul 6 2000
    
    @cvs-id delete-page.tcl,v 3.1.2.4 2000/09/22 01:36:08 kevin Exp
} {
    page_id:notnull
    {cascade f}
}


# throw out the user history
db_dml remove_mapping "delete from user_content_map where page_id=:page_id"

if { $cascade == "t" } {
    db_dml remove_from_comments "delete from comments where page_id=:page_id"
    db_dml remove_from_links "delete from links where page_id=:page_id"
}    

if [catch { db_dml remove_from_static "delete from static_pages where page_id=:page_id"}] {
    # error, it must have some child rows
    set result "Couldn't delete that page: probably there are comments or links 
    that refer to it.  You may:<ul>
    <li><a href=delete-page?cascade=t&[export_url_vars page_id]>Delete all comments, links, and user history associated with this page</a>
    <li><a href=mark-page-obsolete?[export_url_vars page_id]>Mark this page obsolete</a>
    </ul>"
} else {
    # successfully deleted
    set result "Successfully deleted the page."
}



doc_return  200 text/html $result
