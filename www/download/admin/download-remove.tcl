# /www/download/admin/download-remove.tcl
ad_page_contract {
    removes a download

    @param download_id the download to remove

    @author ahmeds@mit.edu
    @creation-date 4 Jan 2000
    @cvs-id download-remove.tcl,v 3.10.2.6 2000/09/24 22:37:15 kevin Exp
} {
    download_id:integer
    scope:optional
    group_id:optional
}

# -----------------------------------------------------------------------------

ad_scope_error_check

ad_scope_authorize $scope admin group_admin none
set user_id [download_admin_authorize $download_id]

set sql_query "
select download_name
from   downloads 
where  download_id=:download_id"

if {[catch {db_1row name_for_one_download $sql_query} errmsg]} {
    ad_scope_return_error \
	    "Error in finding the data" \
	    "We encountered the following error in querying the database for your object:
    <blockquote>$errmsg</blockquote>"
    return
} 

set counter [db_string num_versions "
select count(*) from download_versions 
where download_id = :download_id "]

set version_count_html [ad_decode $counter 0 "" "with $counter downloadable version(s)"]

# -----------------------------------------------------------------------------

set page_title "Remove $download_name" 

doc_return 200 text/html "
[ad_scope_header $page_title]
[ad_scope_page_title $page_title]
[ad_scope_context_bar_ws \
	[list "/download/index?[export_url_scope_vars]" "Download"] \
	[list "/download/admin/index?[export_url_scope_vars]" "Admin"] \
	[list "download-view?[export_url_scope_vars download_id]" "$download_name"]  \
	"Remove"]

<hr>

<p>Are you sure that you want to <b>permanently remove</b> $download_name $version_count_html? </p> 

<center>
<form method=post action=download-remove-2>
[export_form_scope_vars download_id]
<input type=submit value=\"Yes, I want to remove it!\">
</form>
</center>

[ad_scope_footer]
"
