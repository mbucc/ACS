# $Id: download-view.tcl,v 3.0 2000/02/06 03:16:39 ron Exp $
# File:     /admin/download/download-view.tcl
# Date:     01/04/2000
# Author :  ahmeds@mit.edu
# Purpose:  
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

set_the_usual_form_variables
# download_id

set db [ns_db gethandle]

set selection [ns_db 1row $db "
    select download_name, directory_name, description, html_p, scope, group_id
    from downloads 
    where download_id=$download_id"]
set_variables_after_query

#now we have the values from the database.

set description_string [ad_decode $description "" None $description]
set html_string [ad_decode $description "" "" "<tr><th  align=left>Text above is
                                                   <td>[ad_decode $html_p t HTML "Plain Text"]
</tr>"]

ReturnHeaders

ns_write "
[ad_admin_header "View the entry for $download_name"]
<h2>View the entry for $download_name</h2>
[ad_admin_context_bar [list "index.tcl?[export_url_vars]" "Download"] "View $download_name"]

<hr>

"
set counter [database_to_tcl_string $db "select count(*)
from  download_versions dv, download_log dl
where dl.version_id = dv.version_id
and dv.download_id = $download_id"]

if { $scope == "public" } {
    set maintain_link "/download/admin/download-view.tcl?[export_url_vars download_id scope]"
} else {
    set short_name [database_to_tcl_string $db "select short_name
    from user_groups
    where group_id = $group_id"]    
    
    set maintain_link "/groups/admin/$short_name/download/download-view.tcl?[export_url_vars download_id scope group_id]" 
}
  
append html "

<p>

"

append html "
<p>

<table>
<tr><th valign=top align=left>Download Name [ad_space 1]</th>
<td> $download_name </td></tr>

<tr><th valign=top align=left>Directory Name</th>
<td> $directory_name </td></tr>

<tr><th valign=top align=left>Description</th>
<td> $description_string </td></tr>

$html_string

</table>

<p>

<li><a href=\"$maintain_link\">Maintain Download</a>
"

set counter [database_to_tcl_string $db "select count(*)
from download_versions 
where download_id = $download_id"]

if { $counter > 0 } {
append html "
<li><a href=\"view-versions.tcl?[export_url_vars download_id]\">View All Versions</a>
"
}

set counter [database_to_tcl_string $db "select count(*)
from  download_versions dv, download_log dl
where dl.version_id = dv.version_id
and dv.download_id = $download_id"]

if { $counter > 0 } {

    set selection [ns_db 1row $db "select max(entry_date) as max_entry_date, min(entry_date) as min_entry_date 
    from  download_versions dv, download_log dl
    where dl.version_id = dv.version_id
    and dv.download_id = $download_id"]
    
    set_variables_after_query
    
    append html "
    <p>
    <li><a href=\"view-versions-report.tcl?[export_url_vars download_id]\">Download History</a> : $counter download(s) between 
    [util_AnsiDatetoPrettyDate $min_entry_date] and [util_AnsiDatetoPrettyDate $max_entry_date]
    <p>
    " 
}


ns_write "
<blockquote>
$html
</blockquote>

[ad_admin_footer]"
