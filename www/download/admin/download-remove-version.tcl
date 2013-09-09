# /www/download/admin/download-remove-version.tcl
ad_page_contract {
    removes a version of a download

    @param version_id the version to remove

    @author ahmeds@mit.edu
    @creation-date 4 Jan 2000
    @cvs-id download-remove-version.tcl,v 3.8.2.6 2000/09/24 22:37:15 kevin Exp
} {
    version_id:integer,notnull
    scope:optional
    group_id:optional,integer
}

# -----------------------------------------------------------------------------

ad_scope_error_check

download_version_admin_authorize $version_id

if {! [db_0or1row info_for_one_version "
select download_id, pseudo_filename
from download_versions
where version_id=:version_id"]} {

    ad_scope_return_complain 1 "<li>There is no file with the given version id."
}

db_1row download_name_for_version "
select download_name
from   downloads 
where  download_id = :download_id"

# -----------------------------------------------------------------------------

set page_title "Remove Download Version"

doc_return 200 text/html "
[ad_scope_header $page_title]
[ad_scope_page_title $page_title]
[ad_scope_context_bar_ws \
	[list "/download/index?[export_url_scope_vars]" "Download"] \
	[list "/download/admin/index?[export_url_scope_vars]" "Admin" ] \
	[list "download-view?[export_url_scope_vars download_id]" "$download_name"] \
	[list "view-versions?[export_url_scope_vars download_id]" "Versions"] \
	[list "view-one-version?[export_url_scope_vars version_id]" "One Version"] \
	"Remove"]

<hr>

<blockquote>
<form method=get action=download-remove-version-2>
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
