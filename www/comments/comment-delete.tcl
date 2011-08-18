# $Id: comment-delete.tcl,v 3.0.4.1 2000/04/28 15:09:53 carsten Exp $
set_form_variables

# comment_id

set db [ns_db gethandle]

set selection [ns_db 1row $db "select url_stub,nvl(page_title, url_stub) page_title
from static_pages
where static_pages.page_id = $page_id"]

set_variables_after_query

if { [regexp -nocase "delete" $submit] } {
 
    #user would like to delete

    ns_db dml $db "delete from comments where comment_id=$comment_id"
   
    ns_return 200 text/html "[ad_header "Comment Deleted"]
    
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



