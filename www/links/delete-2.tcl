# $Id: delete-2.tcl,v 3.0 2000/02/06 03:49:27 ron Exp $
if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set_the_usual_form_variables

# page_id, url

set db [ns_db gethandle]

set selection [ns_db 1row $db "select url_stub, nvl(page_title, url_stub) as page_title
from static_pages
where static_pages.page_id = $page_id"]
set_variables_after_query

set user_id [ad_get_user_id]
ns_db dml $db "delete from links where page_id=$page_id and url='$QQurl' and user_id = $user_id"

ns_return 200 text/html "[ad_header "Link Deleted"]
    
<h2>Link Deleted</h2>

from <a href=\"$url_stub\">$page_title</a>
<hr>
<p>
Return to  <a href=\"$url_stub\">$page_title</a>
<p>
[ad_footer]"




