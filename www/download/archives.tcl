# $Id: archives.tcl,v 3.0.4.2 2000/05/18 00:05:14 ron Exp $
# File:     /download/archives.tcl
# Date:     Wed Jan  5 21:10:54 EST 2000
# Author:   mobin@mit.edu
# Purpose:  download module user page. Allows users to download
#           all the files which are available for download.
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

# ----------------------- initialHtmlGeneration codeBlock ----

# We might want this incase scope, group_id are passed
set_form_variables 0
# maybe scope, maybe scope related variables (group_id)

# Return the http headers. (an awefully useless comment)
ReturnHeaders

# Check for scope and wards off url surgery's evils
ad_scope_error_check

# Set the page title
set title "Archive of all downloads"

# The database handle (another thoroughly useless comment)
set db [ns_db gethandle]

# Send the first packet of html. The reason for sending the
# first packet (with the page heading) as early as possible
# is that otherwise the user might find the system somewhat
# unresponsive if it takes too long to query the database.
ns_write "
[ad_scope_header $title $db]
[ad_scope_page_title $title $db]
[ad_scope_context_bar_ws_or_index [list "index.tcl" "Download"] $title]
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
  d.download_name as pretty_name
from download_versions dv, downloads d
where dv.status != 'removed'
and dv.download_id=d.download_id
and dv.release_date <= sysdate
and [ad_scope_sql d]
order by pretty_name, ver asc
"

# Get the results of the query...
set selection [ns_db select $db $sql_query] 

# This counter will keep track of the number of rows returned
# by the query
set counter 0

set html "
<h3>All files</h3>
"

# And loop through the rows returned by the query
while { [ns_db getrow $db $selection] } {
    # Set the variables to represent the field values of the
    # particular row of the result that we are processing now.
    set_variables_after_query
    # Increment the counter so that we have accounted for this
    # particular row in the total count
    incr counter

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
	<a href=\"download-input.tcl?[export_url_vars version_id pseudo_filename]\">$pretty_name $ver_html</a><br>"
    } else {
	append html "
	<li>
	<a href=\"download-input.tcl?[export_url_vars version_id pseudo_filename]\">$pretty_name $ver_html</a><br>"
    }
}

# If the counter reads zero, then there were no downloadable files
if { $counter == 0 } {
    # Give user a message stating there were no downloadable files.
    set html "The archive is empty.<p>"
}

# ------------------------ htmlFooterGeneration codeBlock ----

# And here is our footer. Were you expecting someone else?
ns_write "
<blockquote>
$html
</blockquote>
[ad_scope_footer]
"

# EOF
