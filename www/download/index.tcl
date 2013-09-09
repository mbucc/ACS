# /www/download/index.tcl

ad_page_contract {

    Download site wide user index page.

    @author ahmeds@mit.edu
    @author mobin@mit.edu
    @creation-date 5 Jan 2000
    @cvs-id index.tcl,v 3.16.2.8 2000/10/06 22:53:43 ron Exp
} {
    scope:optional
    group_id:integer,optional
}

# -----------------------------------------------------------------------------


# First, we need to get the user_id
set user_id [ad_verify_and_get_user_id]

# Check for scope and wards off url surgery's evils
ad_scope_error_check 

set title "Download"

# ------------------------------- databaseQuery codeBlock ----

# This query will extract the list of all the files that are
# available for download at the main page.

set sql_query "
select dv.version_id as version_id, 
       dv.download_id as did, 
       dv.release_date, 
       dv.pseudo_filename as pseudo_filename, 
       dv.version as ver,
       d.scope as file_scope, 
       d.group_id as gid, 
       d.directory_name as directory, 
       d.download_name as pretty_name
from   download_versions dv, 
       downloads d
where  dv.status = 'promote'
and    dv.download_id = d.download_id
and    (download_viewable_p (dv.version_id, :user_id)) = 'authorized'
and    dv.release_date <= sysdate
and    [ad_scope_sql d]
order by pretty_name, ver desc" 



# We will display the list of available files in a table
set html "
<h3>Current files</h3>
<table>"

set other_html ""

# And loop through the rows returned by the query
db_foreach info_for_each_version $sql_query {

    if {$file_scope == "public"} {
	set full_filename "[ad_parameter DownloadRoot download]$directory/$version_id.file"
    } else {
	# scope is group
	# download_authorize $did
	set full_filename "[ad_parameter DownloadRoot download]groups/$gid/$directory/$version_id.file"
    }
    

    if { [empty_string_p $ver] } {
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

    # We need to find if this download has other versions which are
    # underpriveleged and not under promotion. If the count is not
    # zero then we need to add a link to other versions.
    set other_versions_p [db_string other_versions "
    select count(*) from download_versions
    where  status = 'offer_if_asked'
    and    (download_viewable_p (version_id, :user_id)) = 'authorized'
    and    release_date <= sysdate
    and    download_id = :did"]

    # If there are other available versions, we need to provide a
    # link to them.
    if {$other_versions_p > 0} {
	set other_html "
	(<a href=one?download_id=$did&download_name=[ns_urlencode $pretty_name]>other versions</a>)"
    }

    # This will maintain html that will have the list of all the
    # files that can be downloaded.
    append html "
    <tr>
    <td>
<a href=\"download-input?[export_url_scope_vars version_id pseudo_filename]\">$pretty_name $ver_html</a>  ([expr [file size $full_filename] / 1000]k)
&nbsp; $other_html
</td></tr>
"
    
} if_no_rows {
    # Give user a message stating there were no downloadable files.
    append html "<tr><td>
<p>No files are currently available for download.</p>
</td></tr>"
}

append html "</table>"

# And finally, append a link to the archive of all available files
# This query will extract the list of all the files that are
# available for download at the main page.

set archive_file_counter [db_string file_count "
select count(*)
from   download_versions dv, 
       downloads d
where  dv.status != 'removed'
and    dv.download_id = d.download_id
and    (download_viewable_p (dv.version_id, :user_id)) = 'authorized'
and    dv.release_date <= sysdate
and    [ad_scope_sql d]"]

if { $archive_file_counter > 0 } {
    append html "
    <br>
    <a href=archives?[export_url_scope_vars]>
    Archive of all files available for download
    </a>
    "
}

append page_content "
[ad_scope_header $title]
[ad_scope_page_title $title]
[ad_scope_context_bar_ws_or_index $title]
<hr>
[help_upper_right_menu]
<blockquote>
$html
</blockquote>
[ad_scope_footer]
"

doc_return 200 text/html $page_content

