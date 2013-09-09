# /www/download/one.tcl
ad_page_contract {
    download module user page. Allows users to download
    all the files of a particular download which have
    a status of offer_if_asked

    @param download_id the ID of the file to view
    @param download_name the name of the file
    @param scope
    @param group_id

    @author mobin@mit.edu
    @author ahmeds.mit.edu
    @creation-date 5 Jan 2000
    @cvs-id one.tcl,v 3.6.2.6 2000/09/24 22:37:12 kevin Exp
} {
    scope:optional
    group_id:optional,integer
    download_id:integer
    download_name:trim
}

# -----------------------------------------------------------------------------


# Check for scope and wards off url surgery's evils
ad_scope_error_check

set user_id [ad_verify_and_get_user_id]

set html "
<h3>Other Versions of $download_name</h3>
"


# This query will extract the list of all the files that are
# available for download at the main page.
set sql_query "
select dv.version_id as version_id, 
  dv.download_id as did, 
  dv.release_date, 
  dv.pseudo_filename as pseudo_filename,
  dv.version as ver,
  dv.status as status,
  d.scope as file_scope, 
  d.group_id as gid, 
  d.directory_name as directory,
  d.download_name as pretty_name
from download_versions dv, downloads d
where dv.status = 'offer_if_asked'
and dv.download_id=d.download_id
and dv.download_id=:download_id
and dv.release_date <= sysdate
and [ad_scope_sql d]
order by pretty_name, ver asc
"

db_foreach download_versions $sql_query {

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
    if { $status == "promote" } {
	append html "
	<li>
	<a href=\"download-input?[export_url_vars version_id pseudo_filename]\">*$pretty_name $ver_html</a>([expr [file size $full_filename] / 1000]k)<br>"
    } else {
	append html "
	<li>
	<a href=\"download-input?[export_url_vars version_id pseudo_filename]\">$pretty_name $ver_html</a>([expr [file size $full_filename] / 1000]k)<br>"
    }
} if_no_rows {

    set html "<li>There are no other versions of $download_name right now.<p>"
}

# -----------------------------------------------------------------------------

set title "Other Versions"

doc_return 200 text/html "
[ad_scope_header $title]
[ad_scope_page_title $title]
[ad_scope_context_bar_ws_or_index [list "index?[export_url_scope_vars]" "Download"] $title]
<hr>

<blockquote>
$html
</blockquote>
[ad_scope_footer]
"
















