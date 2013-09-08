# /www/download/admin/download/spam-all-downloaders.tcl
ad_page_contract {
    spams all users who downloaded this file 

    @param download_id the download we are spamming about
    @param scope
    @param group_id
    
    @author ahmeds@mit.edu
    @creation-date 4 Jan 2000
    @cvs-id spam-all-downloaders.tcl,v 3.10.2.6 2000/09/24 22:37:17 kevin Exp
} {
    download_id:integer,notnull
    scope:optional
    group_id:optional
}

# -----------------------------------------------------------------------------

ad_scope_error_check

set user_id [download_admin_authorize $download_id]

db_1row download_name "
select download_name
from   downloads 
where  download_id = :download_id"

set from_address [db_string from_email "
select email from users where user_id = :user_id"]

# -----------------------------------------------------------------------------

db_release_unused_handles

set page_title "Spam All Users who downloaded $download_name"

doc_return 200 text/html "
[ad_scope_header $page_title]
[ad_scope_page_title $page_title]
[ad_scope_context_bar_ws \
	[list "/download/index?[export_url_scope_vars]" "Download"] \
	[list "/download/admin/index?[export_url_scope_vars]" "Admin"] \
	[list "download-view?[export_url_scope_vars download_id]" "$download_name"] \
	[list "view-versions-report?[export_url_scope_vars download_id]" "Report"] \
	"Spam" ]

<hr>
[help_upper_right_menu]

<blockquote>
<form method=post action=spam-all-downloaders-1>
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







