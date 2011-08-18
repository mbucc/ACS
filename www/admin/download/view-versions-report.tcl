# $Id: view-versions-report.tcl,v 3.1 2000/02/15 02:07:26 ahmeds Exp $
# File:     /admin/download/view-versions-report.tcl
# Date:     01/04/2000
# Author :  ahmeds@mit.edu
# Purpose:  displays summary of this download ( who downloaded for what reason)
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

set_the_usual_form_variables
# download_id


set db_pool [ns_db gethandle [philg_server_default_pool] 2]
set db [lindex $db_pool 0]
set db2 [lindex $db_pool 1]

set user_id [download_admin_authorize $db $download_id]

set download_name [database_to_tcl_string $db "
select download_name
from downloads 
where download_id = $download_id"]

set page_title "View Download Report of $download_name"

ReturnHeaders 

ns_write "
[ad_admin_header $page_title]
<h2>$page_title</h2>
[ad_admin_context_bar [list "index.tcl?[export_url_vars]" "Download"] "View Report"]

<hr>
[help_upper_right_menu]
"


set selection [ns_db select $db "
select user_id, entry_date, ip_address, version, 
status, log_id , download_reasons, dl.version_id as version_id
from  download_versions dv, download_log dl
where dl.version_id = dv.version_id
and dv.download_id = $download_id
order by entry_date desc"]

set counter 0

append table_html "
<center>
<table cellpadding=3 border=1>
<tr>
<th  align=center>[ad_space 2] User Name [ad_space 2]  </th>
<th  align=center>[ad_space 2] Email [ad_space 2]  </th>
<th  align=center>[ad_space 2] Download Date[ad_space 2]  </th>
<th  align=center>[ad_space 5] IP Address[ad_space 5]  </th>
<th  align=center>[ad_space 2] Version[ad_space 2]  </th>
<th  align=center>[ad_space 2] Status[ad_space 2]  </th>
<th  align=center>[ad_space 2] Download Reason[ad_space 2] </th>
</tr>
"

while { [ns_db getrow $db $selection] } {
    set_variables_after_query

    if { [empty_string_p $user_id] } {
	set email_string "Unavailable"
	set name_string "Anonymous"	
    } else {
	set sub_selection [ns_db 1row $db2 "
	select email, first_names, last_name
	from users
	where user_id = $user_id "]
	
	set_variables_after_subquery
	
	set email_string "<a href=\"mailto:$email\"><address>$email</address></a>"
	set name_string "$first_names $last_name"	
    }
    

    set dl_reason_html [ad_decode $download_reasons "" None "<a href=download-reason-view.tcl?[export_url_vars log_id version_id]>view</a>"]

    append table_html "
    <tr>
    <td  align=left>$name_string</td>
    <td  align=left>$email_string</td>
    <td  align=center>[util_AnsiDatetoPrettyDate $entry_date]</td>
    <td  align=center>$ip_address</td>
    <td  align=center>$version</td>
    <td  align=left>$status</td>
    <td  align=center>$dl_reason_html</td>
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
    There is no log information in the database about this particular download.
    "
}

ns_write "
<blockquote>
$html
</blockquote>
[ad_admin_footer]
"


