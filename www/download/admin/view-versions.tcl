# /www/download/admin/view-versions.tcl
ad_page_contract {
    displays different versions of one download

    @param download_id the file we are viewing versions of
    @param scope
    
    @author ahmeds@mit.edu
    @creation-date 4 Jan 2000
    @cvs-id view-versions.tcl,v 3.11.2.6 2000/09/24 22:37:18 kevin Exp
} {
    download_id:integer,notnull
    scope:optional
}

# -----------------------------------------------------------------------------

ad_scope_error_check

set user_id [download_admin_authorize $download_id]

db_0or1row download_name "
select d.download_name as download_name,
       d.scope as file_scope, 
       d.group_id as gid, 
       d.directory_name as directory
from downloads d
where download_id = :download_id"


# ------------------------------- databaseQuery codeBlock ----

# This query will extract the list of all the files that are
# available for download 
set sql_query "
select version_id as vid, 
       version as ver
from download_versions 
where download_id = :download_id
and status != 'removed'
order by ver asc, version_id desc
"

db_foreach available_versions $sql_query {
     
    if {$file_scope == "public"} {
	set full_filename "[ad_parameter DownloadRoot download]$directory/$vid.file"
    } else {
	# scope is group
	# download_authorize $did
	set full_filename "[ad_parameter DownloadRoot download]groups/$gid/$directory/$vid.file"
    }

    if {![info exists ver] || [empty_string_p $ver]} {
	# If no version info exists in database (=> the file has no
	# particular version number associated with it) then we do
	# not display version information besides the filename while
	# listing the file for user download
	set ver_html ""
    } else {
	# If version number is associated with file then we will
	# want to show it next to the filename.
	set ver_html "v.$ver"
    }

    append current_html "
    <li><a href=\"view-one-version?[export_url_scope_vars]&version_id=$vid\">$download_name $ver_html</a> ([expr [file size $full_filename] / 1000]k) 
    <br>
    "
 
} if_no_rows {

    append current_html "<li>There are no files available for download right now.<p>"
} 

append current_html "</ul>"


append removed_html "
<b>Removed Versions </b> <br>
<ul>
"

# This query will extract the list of all the files that are removed
set sql_query "
select version_id as vid, 
       version as ver
 from download_versions 
where download_id = :download_id
and status = 'removed'
order by ver asc, version_id desc
"

db_foreach removed_versions $sql_query {
     
    if {$file_scope == "public"} {
	set full_filename "[ad_parameter DownloadRoot download]$directory/$vid.file"
    } else {
	# scope is group
	# download_authorize $did
	set full_filename "[ad_parameter DownloadRoot download]groups/$gid/$directory/$vid.file"
    }

    if {![info exists ver] || [empty_string_p $ver]} {
	set ver_html ""
    } else {
	set ver_html "v.$ver"
    }

    append removed_html "
    <li><a href=\"view-one-version?[export_url_scope_vars]&version_id=$vid\">$download_name $ver_html</a> ([expr [file size $full_filename] / 1000]k)<br>
    "
 
} if_no_rows {
    set removed_html "<i>No removed version</i>"
}

append removed_html "</ul>"

append page_content "
$current_html
$removed_html
"
# -----------------------------------------------------------------------------

set page_title "$download_name Versions"

doc_return 200 text/html "
[ad_scope_header $page_title]
[ad_scope_page_title $page_title]
[ad_scope_context_bar_ws \
	[list "/download/index?[export_url_scope_vars]" "Download"] \
	[list "/download/admin/index?[export_url_scope_vars]" "Admin"] \
	[list "download-view?[export_url_scope_vars download_id]" "$download_name"] \
	"Versions"]
<hr>
[help_upper_right_menu]

<blockquote>
$page_content
</blockquote>

[ad_scope_footer]
"
