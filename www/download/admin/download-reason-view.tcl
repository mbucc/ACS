# /www/download/admin/download-reason-view.tcl
#
# Date:     01/04/2000
# Author :  ahmeds@mit.edu
# Purpose:  displays download reason for this log id
#
# $Id: download-reason-view.tcl,v 3.1.6.2 2000/05/18 00:05:16 ron Exp $
# -----------------------------------------------------------------------------

set_the_usual_form_variables
# maybe scope, maybe scope related variables (group_id)
# log_id version_id 

ad_scope_error_check

set db [ns_db gethandle]
ad_scope_authorize $db $scope admin group_admin none

set selection [ns_db 1row $db "
select download_name , version, pseudo_filename, dv.download_id as did
from downloads d, download_versions dv
where d.download_id = dv.download_id
and dv.version_id = $version_id"]

set_variables_after_query

set download_reasons [database_to_tcl_string $db \
	"select download_reasons from download_log where log_id = $log_id"]

if { ![empty_string_p $download_reasons] } {   
    set html "
    <p>
    <table border=0>
    <tr><th align=left valign=top>Reason for Download : </th> 
    <td>[ad_space 5]<textarea name=download_reasons cols=45 rows=6 wrap=soft>$download_reasons</textarea></td></tr>
    </table>
    <p>
    "
} else {
    set html "<p>No reason was given for this download.\n"
}

# -----------------------------------------------------------------------------

set page_title "Download Reason for $pseudo_filename"

ns_return 200 text/html "
[ad_scope_header $page_title $db]
[ad_scope_page_title $page_title $db]
[ad_scope_context_bar_ws \
	[list "/download/" "Download"] \
	[list "/download/admin/" "Admin"] \
	[list "download-view.tcl?[export_url_scope_vars download_id]" "$download_name"] \
	[list "view-versions.tcl?[export_url_scope_vars]&download_id=$did " "Versions"] \
	[list "view-one-version-report.tcl?[export_url_scope_vars version_id]" "Report"] \
	"Download Reason"]

<hr>

<blockquote>
$html
</blockquote>

[ad_scope_footer]
"
