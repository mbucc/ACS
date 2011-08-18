# /www/download/admin/view-versions.tcl
#
# Author:  ahmeds@mit.edu
# Date:     01/04/2000
# Purpose:  displays different versions of one download
#
# $Id: view-versions.tcl,v 3.0.4.1 2000/04/12 09:00:52 ron Exp $

set_the_usual_form_variables
# download_id

ad_scope_error_check

set db [ns_db gethandle]

set user_id [download_admin_authorize $db $download_id]

set download_name [database_to_tcl_string $db "
select download_name 
from downloads
where download_id = $download_id"]

# ------------------------------- databaseQuery codeBlock ----


# This query will extract the list of all the files that are
# available for download 
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

while { [ns_db getrow $db $selection] } {

    set_variables_after_query

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
    <li><a href=\"view-one-version.tcl?[export_url_scope_vars]&version_id=$vid\">$download_name $ver_html</a> 
    <br>
    "
 
}

# If the counter reads zero, then there were no downloadable files
if { $counter == 0 } {
    set current_html "<li>There are no files available for download right now.<p>"
} else {
    append current_html "</ul>"
}

append removed_html "
<b>Removed Versions </b> <br>
<ul>
"

# This query will extract the list of all the files that are removed
set sql_query "
select version_id as vid, 
       version as ver
 from download_versions 
where download_id = $download_id
and status = 'removed'
order by ver asc, version_id desc
"

set selection [ns_db select $db $sql_query] 

set counter 0

while { [ns_db getrow $db $selection] } {
    set_variables_after_query

    incr counter

    if {![info exists ver] || [empty_string_p $ver]} {
	set ver_html ""
    } else {
	set ver_html "v.$ver"
    }

    append removed_html "
    <li><a href=\"view-one-version.tcl?[export_url_scope_vars]&version_id=$vid\">$download_name $ver_html</a><br>
    "
 
}

# If the counter reads zero, then there were no downloadable files with status = removed
if { $counter > 0 } {
    append removed_html "</ul>"
} else {
    set removed_html ""
}

append html "
$current_html
$removed_html
"
# -----------------------------------------------------------------------------

set page_title "$download_name Versions"

ns_return 200 text/html "
[ad_scope_header $page_title $db]
[ad_scope_page_title $page_title $db]
[ad_scope_context_bar_ws \
	[list "/download/" "Download"] \
	[list "/download/admin/" "Admin"] \
	[list "download-view.tcl?[export_url_scope_vars download_id]" "$download_name"] \
	"Versions"]
<hr>
[help_upper_right_menu]

<blockquote>
$html
</blockquote>

[ad_scope_footer]
"
