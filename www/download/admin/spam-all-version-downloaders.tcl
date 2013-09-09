# /www/download/admin/spam-all-version-downloaders.tcl
ad_page_contract {
    spams all users who downloaded this version

    @param version_id the version we are spamming about
    @param scope
    @param group_id
    
    @author ahmeds@mit.edu
    @creation-date  4 Jan 2000
    @cvs-id spam-all-version-downloaders.tcl,v 3.10.2.6 2000/09/24 22:37:17 kevin Exp
} {
    version_id:integer,notnull
    scope:optional
    group_id:optional
}

# -----------------------------------------------------------------------------

ad_scope_error_check


set user_id [download_version_admin_authorize $version_id]

if { ![db_0or1row all_version_info "
select * from download_versions 
where version_id=:version_id"]} {

    ad_scope_return_complaint 1 "<li>There is no file with the given version id."
    return
}

db_1row download_name "
select download_name
from   downloads 
where  download_id = :download_id" 


# -----------------------------------------------------------------------------

set page_title "Spam All Users who downloaded $pseudo_filename"

doc_return 200 text/html "
[ad_scope_header $page_title]
[ad_scope_page_title $page_title]
[ad_scope_context_bar_ws \
	[list "/download/index?[export_url_scope_vars]" "Download"] \
	[list "/download/admin/index?[export_url_scope_vars]" "Admin"] \
	[list "download-view?[export_url_scope_vars download_id]" "$download_name"] \
	[list "view-versions?[export_url_scope_vars download_id]" "Versions"] \
	[list "view-one-version?[export_url_scope_vars version_id]" "One Version"] \
	[list "view-one-version-report?[export_url_scope_vars version_id]" "Report"] \
	"Spam" ]

<hr>
[help_upper_right_menu]

<blockquote>
<form method=POST action=\"spam-all-version-downloaders-1\">
[export_form_scope_vars version_id]
<table>

<tr><th align=left>From</th>
<td><input name=from_address type=text size=30 
value=\"[db_string unused "select email from users where user_id =[ad_get_user_id]"]\"></td></tr>

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

</blockquote>
[ad_scope_footer]
"
