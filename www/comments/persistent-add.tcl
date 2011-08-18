# $Id: persistent-add.tcl,v 3.0.4.1 2000/04/28 15:09:53 carsten Exp $
if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set_form_variables
# page_id

set user_id [ad_get_user_id]
if {$user_id == 0} {
    ad_returnredirect /register.tcl?return_url=[ns_urlencode  /comments/persistent-add.tcl?[export_url_vars page_id]]
}

set db [ns_db gethandle]
set selection [ns_db 1row $db "select  nvl(page_title,url_stub) as page_title, url_stub 
from static_pages
where page_id = $page_id"]
set_variables_after_query
ns_db releasehandle $db

ns_return 200 text/html "[ad_header "Add a comment to $page_title" ]

<h2>Add a comment</h2>
to <a href=\"$url_stub\">$page_title</a>
<hr>

What comment or alternative perspective
would you like to add to this page?<br>
<form action=persistent-add-2.tcl method=post>
[export_form_vars page_id comment_id]
<textarea name=message cols=70 rows=10 wrap=soft></textarea><br>
<input type=hidden name=comment_type value=alternative_perspective>
<br>
Text above is
<select name=html_p><option value=f>Plain Text<option value=t>HTML</select>
<p>
<center>
<input type=submit name=submit value=\"Proceed\">
</center>
</form>
[ad_footer]
"
