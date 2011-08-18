# /www/download/admin/spam-all-version-downloaders.tcl
#
# Date:     01/04/2000
# Author :  ahmeds@mit.edu
# Purpose: spams all users who downloaded this version
#
# $Id: spam-all-version-downloaders.tcl,v 3.0.6.1 2000/04/12 09:00:48 ron Exp $
# -----------------------------------------------------------------------------

set_the_usual_form_variables
# maybe scope, maybe scope related variables (group_id)
# version_id

ad_scope_error_check

set db [ns_db gethandle]

set user_id [download_version_admin_authorize $db $version_id]


set selection [ns_db 0or1row $db \
	"select * from download_versions where version_id=$version_id"]

set exception_count 0
set exception_text ""

if { [empty_string_p $selection] } {
    incr exception_count
    append exception_text "<li>There is no file with the given version id."
} else {
    set_variables_after_query
}

if { $exception_count >0 } {
    ad_scope_return_complaint $exception_count $exception_text $db
    return
}

set download_name [database_to_tcl_string $db "
select download_name
from   downloads 
where  download_id = $download_id"]

append html "
<form method=POST action=\"spam-all-version-downloaders-1.tcl\">
[export_form_scope_vars version_id]
<table>

<tr><th align=left>From</th>
<td><input name=from_address type=text size=30 
value=\"[database_to_tcl_string $db "select email from users where user_id =[ad_get_user_id]"]\"></td></tr>

<tr><td></td></tr>

<tr><th align=left>Subject</th><td> <input name=subject type=text size=50></td></tr>

<tr><td></td></tr>

<tr><th align=left valign=top>Message</th><td><font size=-1>
<textarea name=message rows=13 cols=70 wrap=hard></textarea></font>
</td></tr>

</table>

<center>
<p>
<input type=submit value=\"Send Mail\">
</center>
</form>
<p>
"

# -----------------------------------------------------------------------------

set page_title "Spam All Users who downloaded $pseudo_filename"

ns_return 200 text/html "
[ad_scope_header $page_title $db]
[ad_scope_page_title $page_title $db]
[ad_scope_context_bar_ws \
	[list "/download/" "Download"] \
	[list "/download/admin/" "Admin"] \
	[list "download-view.tcl?[export_url_scope_vars download_id]" "$download_name"] \
	[list "view-versions.tcl?[export_url_scope_vars download_id]" "Vesrions"] \
	[list "view-one-version.tcl?[export_url_scope_vars version_id]" "One Version"] \
	[list "view-one-version-report.tcl?[export_url_scope_vars version_id]" "Report"] \
	"Spam" ]

<hr>
[help_upper_right_menu]

<blockquote>
$html
</blockquote>
[ad_scope_footer]
"
