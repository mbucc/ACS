# $Id: delete.tcl,v 3.0 2000/02/06 03:49:28 ron Exp $
if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set_the_usual_form_variables

# url, page_id

set db [ns_db gethandle]
set user_id [ad_verify_and_get_user_id]

set selection [ns_db 1row $db "select  nvl(page_title,url_stub) as page_title, url_stub 
from static_pages
where page_id = $page_id"]
set_variables_after_query

set selection [ns_db 1row $db "select url, link_title, link_description from links where page_id = $page_id and url='$QQurl' and user_id=$user_id"]
set_variables_after_query

ns_return 200 text/html "[ad_header "Verify deletion"]
    
<h2>Verify Deletion</h2>
to <a href=\"$url_stub\">$page_title</a>

<hr>
Would you like to delete the following link?
<p>
<a href=\"$url\">$link_title</a> - $link_description
<p>
<table>
<tr><td>
<form action=delete-2.tcl method=post>
[export_form_vars page_id url]
<center>
<input type=submit value=\"Delete Link\" name=submit>
</form>
</td><td>
<form action=\"$url_stub\">
<input type=submit value=\"Cancel\" name=submit>
</form>
</td></tr>
</table>
</center>
</form>
[ad_footer]"
