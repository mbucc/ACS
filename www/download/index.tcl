# /www/download/index.tcl
#
# Download site wide user index page.
#
# Author:   ahmeds@mit.edu, mobin@mit.edu
# Date:     Wed Jan  5 11:32:17 EST 2000
#
# $Id: index.tcl,v 3.2.4.2 2000/05/18 00:05:14 ron Exp $

# ----------------------- initialHtmlGeneration codeBlock ----

# First, we need to get the user_id
set user_id [ad_verify_and_get_user_id]

# We might want this in case scope, group_id are passed
set_form_variables 0
# maybe scope, maybe scope related variables (group_id)

# Check for scope and wards off url surgery's evils
ad_scope_error_check 


set db_pools [ns_db gethandle [philg_server_default_pool] 2]
# The first handle is for our main query
set db [lindex $db_pools 0]
# The second handle is used to determine the number of
# 'offer_if_asked' versions of a particular download.
set db2 [lindex $db_pools 1]

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
       d.download_name as pretty_name
from   download_versions dv, 
       downloads d
where  dv.status = 'promote'
and    dv.download_id = d.download_id
and    (download_viewable_p (dv.version_id, $user_id)) = 'authorized'
and    dv.release_date <= sysdate
and    [ad_scope_sql d]
order by pretty_name, ver desc"

# Get the results of the query...
set selection [ns_db select $db $sql_query] 

# This counter will keep track of the number of rows returned
# by the query
set counter 0

# We will display the list of available files in a table
set html "
<h3>Current files</h3>
<table>"

set other_html ""

# And loop through the rows returned by the query
while { [ns_db getrow $db $selection] } {
    # Set the variables to represent the field values of the
    # particular row of the result that we are processing now.
    set_variables_after_query
    # Increment the counter so that we have accounted for this
    # particular row in the total count
    incr counter

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
    set other_versions_p [database_to_tcl_string $db2 "
    select count(*) from download_versions
    where  status = 'offer_if_asked'
    and    (download_authorized_p (version_id, $user_id)) = 'authorized'
    and    release_date <= sysdate
    and    download_id = $did"]

    # If there are other available versions, we need to provide a
    # link to them.
    if {$other_versions_p > 0} {
	set other_html "
	(<a href=one.tcl?download_id=$did&download_name=[ns_urlencode $pretty_name]>other versions</a>)"
    }

    # This will maintain html that will have the list of all the
    # files that can be downloaded.
    append html "
    <tr>
    <td>
    <a href=\"download-input.tcl?[export_url_scope_vars version_id pseudo_filename]\">$pretty_name $ver_html</a>
    "
    
}

# And we need to close the <table>
append html "
<tr><td></td>
<tr>
<td>$other_html
</tr>
</table>"


# If the counter reads zero, then there were no downloadable files
if { $counter == 0 } {
    # Give user a message stating there were no downloadable files.
    set html "<p>No files are currently available for download.</p>"
}

# And finally, append a link to the archive of all available files
# This query will extract the list of all the files that are
# available for download at the main page.

set archive_file_counter [database_to_tcl_string $db "
select count(*)
from   download_versions dv, 
       downloads d
where  dv.status != 'removed'
and    dv.download_id = d.download_id
and    (download_authorized_p (dv.version_id, $user_id)) = 'authorized'
and    dv.release_date <= sysdate
and    [ad_scope_sql d]"]

if { $archive_file_counter > 0 } {
    append html "
    <br>
    <a href=archives.tcl>
    Archive of all files available for download
    </a>
    "
}

# Release the primary database handle
ns_db releasehandle $db

# Release the secondary database handle
ns_db releasehandle $db2

# ------------------------ htmlFooterGeneration codeBlock ----

# And here is our footer. Were you expecting someone else?

ns_return 200 text/html "
[ad_scope_header $title $db]
[ad_scope_page_title $title $db]
[ad_scope_context_bar_ws_or_index $title]
<hr>
[help_upper_right_menu]
<blockquote>
$html
</blockquote>
[ad_scope_footer]
"
# ----------------------------
