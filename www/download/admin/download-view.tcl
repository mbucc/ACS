# /www/download/admin/download-view.tcl
#
# Date:     01/04/2000
# Author :  ahmeds@mit.edu
# Purpose:  
#
# $Id: download-view.tcl,v 3.0.4.2 2000/05/18 00:05:16 ron Exp $
# -----------------------------------------------------------------------------

set_the_usual_form_variables
# maybe scope, maybe scope related variables (group_id)
# download_id

ad_scope_error_check

set db [ns_db gethandle]

set user_id [download_admin_authorize $db $download_id]

set selection [ns_db 1row $db "
select download_name, 
       directory_name, 
       description, 
       html_p
from   downloads 
where  download_id = $download_id"]
set_variables_after_query

# now we have the values from the database.

set description_string [ad_decode $description "" None $description]
set html_string [ad_decode $description "" "" "
<tr>
<th align=left>Text above is</th>
<td>[ad_decode $html_p t HTML "Plain Text"]</td>
</tr>"]

set counter [database_to_tcl_string $db "
select count(*) 
from   download_versions dv, 
       download_log dl
where  dl.version_id  = dv.version_id
and    dv.download_id = $download_id"]

set html "

<p>
\[ <a href=\"download-edit.tcl?[export_url_scope_vars download_id]\">Edit</a> |   
   <a href=\"download-remove.tcl?[export_url_scope_vars download_id]\">Remove</a> \]

<p>

<table>
<tr>
<th align=right>Download Name:</th>
<td>$download_name</td>
</tr>

<tr>
<th align=right>Directory Name:</th>
<td>$directory_name</td>
</tr>

<tr>
<th align=right valign=top>Description:</th>
<td>$description_string</td>
</tr>

</table>

<p>

<li>
<a href=download-add-version.tcl?[export_url_scope_vars download_id]>Upload New Version</a>
"

set counter [database_to_tcl_string $db \
	"select count(*) from download_versions where download_id = $download_id"]

if { $counter > 0 } {
    append html "
    <li><a href=\"view-versions.tcl?[export_url_scope_vars download_id]\">View All Versions</a>"
}

append html "<li><a href=\"download-add-rule.tcl?[export_url_scope_vars download_id]\">Add Rule</a>"

set counter [database_to_tcl_string $db "
select count(*)
from   download_versions dv, 
       download_log dl
where  dl.version_id  = dv.version_id
and    dv.download_id = $download_id"]

if { $counter > 0 } {
    set selection [ns_db 1row $db "
    select max(entry_date) as max_entry_date, 
           min(entry_date) as min_entry_date 
    from   download_versions dv, 
           download_log dl
    where  dl.version_id  = dv.version_id
    and    dv.download_id = $download_id"]
    
    set_variables_after_query
    
    append html "
    <p>
    <li>
    <a href=\"view-versions-report.tcl?[export_url_scope_vars download_id]\">Download History</a>: 
    [util_commify_number $counter] download(s) between 
    [util_AnsiDatetoPrettyDate $min_entry_date] and [util_AnsiDatetoPrettyDate $max_entry_date]
    " 
}

# -----------------------------------------------------------------------------

set page_title "View the entry for $download_name"

set page_header "
[ad_scope_header $page_title $db]
[ad_scope_page_title $page_title $db]
[ad_scope_context_bar_ws \
	[list "/download/" "Download"] \
	[list "/download/admin/index.tcl?[export_url_scope_vars]" "Admin"] \
	"$download_name"]

<hr>
"

ns_db releasehandle $db

ns_return 200 text/html "
$page_header
<blockquote>
$html
</blockquote>

[ad_scope_footer]"
