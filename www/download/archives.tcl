# /www/download/archives.tcl
ad_page_contract {
    download module user page. Allows users to download
    all the files which are available for download.

    @param scope
    @param group_id

    @author mobin@mit.edu
    @creation-date 5 Jan 2000
    @cvs-id archives.tcl,v 3.5.2.5 2000/09/24 22:37:12 kevin Exp
} {
    scope:optional
    group_id:optional,integer
}

#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

# -----------------------------------------------------------------------------


# Check for scope and wards off url surgery's evils
ad_scope_error_check

# Set the page title
set title "Archive of all downloads"

# The database handle (another thoroughly useless comment)


# Send the first packet of html. The reason for sending the
# first packet (with the page heading) as early as possible
# is that otherwise the user might find the system somewhat
# unresponsive if it takes too long to query the database.
append page_content "
[ad_scope_header $title ]
[ad_scope_page_title $title ]
[ad_scope_context_bar_ws_or_index [list "index?[export_url_scope_vars]" "Download"] $title]
<hr>
"

set user_id [ad_verify_and_get_user_id]

# ------------------------------- databaseQuery codeBlock ----

# This query will extract the list of all the files that are
# available for download at the main page.
set sql_query "
select dv.version_id as version_id, 
  dv.download_id, 
  dv.release_date, 
  dv.pseudo_filename as pseudo_filename,
  dv.version as ver,
  dv.status as status,
  d.scope as file_scope, 
  d.group_id as gid, 
  d.directory_name as directory,
  d.download_name as pretty_name
from download_versions dv, downloads d
where dv.status != 'removed'
and dv.download_id=d.download_id
and dv.release_date <= sysdate
and [ad_scope_sql d]
order by pretty_name, ver asc
"

set html "
<h3>All files</h3>
"


db_foreach all_version_info $sql_query {

    if {$file_scope == "public"} {
	set full_filename "[ad_parameter DownloadRoot download]$directory/$version_id.file"
    } else {
	# scope is group
	# download_authorize $did
	set full_filename "[ad_parameter DownloadRoot download]groups/$gid/$directory/$version_id.file"
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

    # This will maintain html that will have the list of all the
    # files that can be downloaded.
    
    append html "
    <li>
    <a href=\"download-input?[export_url_vars version_id pseudo_filename]\">$pretty_name $ver_html</a>  ([expr [file size $full_filename] / 1000]k)<br>"
    
} if_no_rows {

    # Give user a message stating there were no downloadable files.
    set html "The archive is empty.<p>"

}


append page_content  "
<blockquote>
$html
</blockquote>
[ad_scope_footer]
"

doc_return 200 text/html $page_content

