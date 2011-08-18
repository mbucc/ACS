# $Id: download-reason-view.tcl,v 3.1 2000/02/15 02:08:06 ahmeds Exp $
# File:     /admin/download/download-reason-view.tcl
# Date:     01/04/2000
# Author :  ahmeds@mit.edu
# Purpose:  displays download reason for this log id

set_the_usual_form_variables
# log_id version_id 

set db [ns_db gethandle]

set selection [ns_db 1row $db "
select download_name , version, pseudo_filename, dv.download_id as did
from downloads d, download_versions dv
where d.download_id = dv.download_id
and dv.version_id = $version_id"]

set_variables_after_query

set page_title "Download Reason for $pseudo_filename"

ReturnHeaders 

ns_write "
[ad_admin_header $page_title]
<h2> $page_title </h2>
[ad_admin_context_bar [list "index.tcl?[export_url_vars]" "Download"]   [list "view-versions-report.tcl?[export_url_vars]&download_id=$did" "Report"] "Download Reason"]

<hr>
"

set download_reasons [database_to_tcl_string $db "select download_reasons
from download_log 
where log_id = $log_id"]

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
    set html "<p>
    No reason was given for this download.
    <p>"
}

ns_write "
<blockquote>
$html
</blockquote>
[ad_admin_footer]
"
