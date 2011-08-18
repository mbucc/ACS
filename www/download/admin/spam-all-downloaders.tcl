# /www/download/admin/download/spam-all-downloaders.tcl
#
# Date:     01/04/2000
# Author :  ahmeds@mit.edu
# Purpose: spams all users who downloaded this file 
#
# $Id: spam-all-downloaders.tcl,v 3.0.6.2 2000/05/18 00:05:17 ron Exp $
# -----------------------------------------------------------------------------

set_the_usual_form_variables
# maybe scope, maybe scope related variables (group_id)
# download_id

ad_scope_error_check

set db [ns_db gethandle]
set user_id [download_admin_authorize $db $download_id]

set download_name [database_to_tcl_string $db "
select download_name
from   downloads 
where  download_id = $download_id"]

set from_address [database_to_tcl_string $db \
	"select email from users where user_id = $user_id"]

ns_db releasehandle $db

# -----------------------------------------------------------------------------

set page_title "Spam All Users who downloaded $download_name"

ns_return 200 text/html "
[ad_scope_header $page_title $db]
[ad_scope_page_title $page_title $db]
[ad_scope_context_bar_ws \
	[list "/download/" "Download"] \
	[list "/download/admin/" "Admin"] \
	[list "download-view.tcl?[export_url_scope_vars download_id]" "$download_name"] \
	[list "view-versions-report.tcl?[export_url_scope_vars download_id]" "Report"] \
	"Spam" ]

<hr>
[help_upper_right_menu]

<blockquote>
<form method=post action=spam-all-downloaders-1.tcl>
[export_form_scope_vars download_id]

<table>

<tr>
<th align=right>From:</th>
<td>
<input name=from_address type=text size=30 value=\"$from_address\">
</td>
</tr>

<tr>
<th align=right>Subject:</th>
<td><input name=subject type=text size=50>
</td>
</tr>

<tr>
<th align=right valign=top>&nbsp;<br>Message:</th>
<td>
<textarea name=message rows=10 cols=70 wrap=hard></textarea>
</td>
</tr>

<tr>
<td></td>
<td><input type=submit value=\"Send Mail\"></td>
</tr>
</table>
</form>
</blockquote>
[ad_scope_footer]
"
