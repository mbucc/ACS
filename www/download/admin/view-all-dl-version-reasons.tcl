# /www/download/admin/view-all-dl-version-reasons.tcl
#
# Date:     01/04/2000
# Author :  ahmeds@mit.edu
# Purpose:  displays all reasons for this download version 
#
# $Id: view-all-dl-version-reasons.tcl,v 3.1.6.1 2000/04/12 09:00:49 ron Exp $

set_the_usual_form_variables
# maybe scope, maybe scope related variables (group_id)
# version_id

ad_scope_error_check

set db_pool [ns_db gethandle [philg_server_default_pool] 2]
set db [lindex $db_pool 0]
set db2 [lindex $db_pool 1]

download_version_admin_authorize $db $version_id

set selection [ns_db 0or1row $db "
select * 
from download_versions
where version_id=$version_id"]

set exception_count 0
set exception_text ""

if { [empty_string_p $selection] } {
    incr exception_count
    append exception_text "<li>There is no file with the given version id."
} else {
    set_variables_after_query
}

if { $exception_count >0 } {
    ad_scope_return_complaint $exception_count $exception_text $db
    return
}

set download_name [database_to_tcl_string $db "
select download_name
from downloads 
where download_id = $download_id"]

set selection [ns_db select $db "
select user_id, download_reasons, dl.version_id as version_id
from  download_versions dv, download_log dl
where dl.version_id = dv.version_id
and dv.version_id = $version_id
and download_reasons is not null
order by entry_date desc"]

set counter 0

append table_html "
<p>

<center>
<table cellpadding=3 border=1>
<tr>
<th  align=center>[ad_space 2] User Name [ad_space 2]  </th>
<th  align=center>[ad_space 2] Download Reason[ad_space 2] </th>
</tr>
"

while { [ns_db getrow $db $selection] } {
    set_variables_after_query

    if { [empty_string_p $user_id] } {
	set name_string "Anonymous"	
    } else {
	set sub_selection [ns_db 1row $db2 "
	select email, first_names, last_name
	from users
	where user_id = $user_id "]
	
	set_variables_after_subquery
	
	set name_string "<a href=\"mailto:$email\"><address>$first_names $last_name</address></a>"
	
    }

    append table_html "
    <tr>
    <td  align=left>$name_string</td>
    <td  align=left>[ad_space 2] $download_reasons</td>
     </tr>
    "
    incr counter
}

if {$counter >0} {
    append table_html "
    </table>
    </center>
    <p>
    "
    append html $table_html
} else {
    set html "
    There is no download reason information in the database about this particular download version.
    "
}

# -----------------------------------------------------------------------------

set page_title "View All Reasons for Downloading $pseudo_filename"

ns_return 200 text/html "
[ad_scope_header $page_title $db]
[ad_scope_page_title $page_title $db]
[ad_scope_context_bar \
	[list "/download/" "Download"] \
	[list "/download/admin/" "Admin"] \
	[list "download-view.tcl?[export_url_scope_vars download_id]" "$download_name"] \
	[list "view-versions.tcl?[export_url_scope_vars download_id]" "Vesrions"] \
	[list "view-one-version.tcl?[export_url_scope_vars version_id]" "One Version"] \
	[list "view-one-version-report.tcl?[export_url_scope_vars version_id]" "Report"] \
	"Reasons" ]

<hr>
[help_upper_right_menu]

<blockquote>
$html
</blockquote>
[ad_scope_footer]
"
