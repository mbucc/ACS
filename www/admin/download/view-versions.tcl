# $Id: view-versions.tcl,v 3.0 2000/02/06 03:16:45 ron Exp $
# File:     /admin/download/view-versions.tcl
# Author:  ahmeds@mit.edu
# Date:     01/04/2000
# Purpose:  displays different versions of one download
#
# ----------------------- initialHtmlGeneration codeBlock ----

set_the_usual_form_variables
# download_id

set db [ns_db gethandle]

set download_name [database_to_tcl_string $db "
select download_name 
from downloads
where download_id = $download_id
"]

# Return the http headers. (an awefully useless comment)
ReturnHeaders


# Set the page title
set title "$download_name Versions"


# Send the first packet of html. The reason for sending the
# first packet (with the page heading) as early as possible
# is that otherwise the user might find the system somewhat
# unresponsive if it takes too long to query the database.
ns_write "
[ad_admin_header $title ]
<h2>$title</h2>
[ad_admin_context_bar [list "index.tcl?[export_url_vars]" "Download"] [list "download-view.tcl?[export_url_vars download_id]" "$download_name"] Versions]

<hr>
[help_upper_right_menu]
"
append current_html "
<b>Current Versions </b><br>
<ul>
"

# ------------------------------- databaseQuery codeBlock ----


# This query will extract the list of all the files that are
# available for download at the main page.
set sql_query "
select version_id as vid, 
       version as ver
from download_versions 
where download_id = $download_id
and status !='removed'
order by ver asc, version_id desc
"

# Get the results of the query...
set selection [ns_db select $db $sql_query] 

# This counter will keep track of the number of rows returned
# by the query
set counter 0

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

    append current_html "
    <li><a href=\"view-one-version.tcl?[export_url_vars]&version_id=$vid\">$download_name $ver_html</a> 
    <br>
    "
 
}

# If the counter reads zero, then there were no downloadable files
if { $counter == 0 } {
    # Give user a message stating there were no downloadable files.
    set current_html "<li>There are no files available for download right now.<p>"
} else {
    append current_html "</ul>"
}

append removed_html "
<b>Removed Versions </b> <br>
<ul>
"

# This query will extract the list of all the files that are
# available for download at the main page.
set sql_query "
select version_id as vid, 
       version as ver
 from download_versions 
where download_id = $download_id
and status = 'removed'
order by ver asc, version_id desc
"

# Get the results of the query...
set selection [ns_db select $db $sql_query] 

# This counter will keep track of the number of rows returned
# by the query
set counter 0

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

    append removed_html "
    <li><a href=\"view-one-version.tcl?[export_url_vars]&version_id=$vid\">$download_name $ver_html</a><br>
    "
 
}

# If the counter reads zero, then there were no removed downloadable files
if { $counter > 0 } {
    append removed_html "</ul>"
} else {
    set removed_html ""
}

append html "
$current_html
$removed_html
"

# ------------------------ htmlFooterGeneration codeBlock ----

# And here is our footer. Were you expecting someone else?
ns_write "
<blockquote>
$html
</blockquote>
<p>
[ad_admin_footer]
"
