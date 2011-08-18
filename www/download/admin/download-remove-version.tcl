# /www/download/admin/download-remove-version.tcl
#
# Date:     01/04/2000
# Author :  ahmeds@mit.edu
# Purpose:  removes the version
#
# $Id: download-remove-version.tcl,v 3.0.4.2 2000/05/18 00:05:16 ron Exp $
# -----------------------------------------------------------------------------

set_the_usual_form_variables
# maybe scope, maybe scope related variables (group_id)
# version_id

ad_scope_error_check

set db [ns_db gethandle]
download_version_admin_authorize $db $version_id

set selection [ns_db 0or1row $db "
select * 
from download_versions
where version_id=$version_id"]

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

# -----------------------------------------------------------------------------

set page_title "Remove Download Version"

ns_return 200 text/html "
[ad_scope_header $page_title $db]
[ad_scope_page_title $page_title $db]
[ad_scope_context_bar_ws \
	[list "/download/" "Download"] \
	[list "/download/admin/" "Admin" ] \
	[list "download-view.tcl?[export_url_scope_vars download_id]" "$download_name"] \
	[list "view-versions.tcl?[export_url_scope_vars download_id]" "Versions"] \
	[list "view-one-version.tcl?[export_url_scope_vars version_id]" "One Version"] \
	"Remove"]

<hr>

<blockquote>
<form method=get action=download-remove-version-2.tcl>
[export_form_scope_vars version_id]

<p>Are you sure that you want to <b>permanently remove</b>
$pseudo_filename from the database and download area?

<p>
<center>
<input type=submit value=\"Yes, I want to remove it!\">
</center>
</form>
</blockquote>

[ad_scope_footer]
"
