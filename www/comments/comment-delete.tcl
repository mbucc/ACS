ad_page_contract {
    @param page_id
    @param comment_id
    @cvs-id comment-delete.tcl,v 3.1.6.5 2000/09/22 01:37:15 kevin Exp
    
} {
    {page_id:naturalnum,notnull}
    {comment_id:naturalnum,notnull}
    submit
}

set selection [db_0or1row comments_delete_page_data_get "
select url_stub,nvl(page_title, url_stub) page_title
from static_pages
where static_pages.page_id = :page_id"]

if {$selection == 0} {
    ad_return_complaint "Invalid page id" "Page id could not be found"
    db_release_unused_handles
    return
}
if { [regexp -nocase "delete" $submit] } {
 
    #user would like to delete
    db_dml comments_comment_delete "delete from comments where comment_id=:comment_id"
   
    doc_return  200 text/html "[ad_header "Comment Deleted"]
    
<h2>Comment Deleted</h2>

<hr>
<p>
Return to  <a href=\"$url_stub\">$page_title</a>
<p>
[ad_footer]"
return

} else {
    # user would like to cancel
    ad_returnredirect $url_stub
    return
}



