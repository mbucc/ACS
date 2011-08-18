# /www/download/one.tcl
#
# Date:     Wed Jan  5 21:10:54 EST 2000
# Author:   mobin@mit.edu , ahmeds@mit.edu
# Purpose:  download module user page. Allows users to download
#           all the files of a particular download which have
#           a status of offer_if_asked
#
# $Id: one.tcl,v 3.0.4.1 2000/04/12 09:00:38 ron Exp $
# -----------------------------------------------------------------------------

# We will be using download_id from parent object (index.tcl)
set_the_usual_form_variables
# maybe scope, maybe scope related variables (group_id)
# download_id, download_name

# Check for scope and wards off url surgery's evils
ad_scope_error_check

# The database handle (what a thoroughly useless comment)
set db [ns_db gethandle]

# ----------------------- initialHtmlGeneration codeBlock ----

set user_id [ad_verify_and_get_user_id]

set html "
<h3>Other Versions of $download_name</h3>
"
# ------------------------------- databaseQuery codeBlock ----

# This query will extract the list of all the files that are
# available for download at the main page.
set sql_query "
select dv.version_id as version_id, 
  dv.download_id as did, 
  dv.release_date, 
  dv.pseudo_filename as pseudo_filename,
  dv.version as ver,
  dv.status as status,
  d.download_name as pretty_name
from download_versions dv, downloads d
where dv.status = 'offer_if_asked'
and dv.download_id=d.download_id
and dv.download_id=$download_id
and dv.release_date <= sysdate
and [ad_scope_sql d]
order by pretty_name, ver asc
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

    # This will maintain html that will have the list of all the
    # files that can be downloaded.
    if { $status == "promote" } {
	append html "
	<li>
	<a href=\"download-input.tcl?[export_url_vars version_id pseudo_filename]\">*$pretty_name $ver_html</a><br>"
    } else {
	append html "
	<li>
	<a href=\"download-input.tcl?[export_url_vars version_id pseudo_filename]\">$pretty_name $ver_html</a><br>"
    }
}

# If the counter reads zero, then there were no downloadable files
if { $counter == 0 } {
    # Give user a message stating there were no downloadable files.
    set html "<li>There are no other versions of $download_name right now.<p>"
}

# -----------------------------------------------------------------------------

set title "Other Versions"

ns_return 200 text/html "
[ad_scope_header $title $db]
[ad_scope_page_title $title $db]
[ad_scope_context_bar_ws_or_index [list "index.tcl" "Download"] $title]
<hr>

<blockquote>
$html
</blockquote>
[ad_scope_footer]
"
