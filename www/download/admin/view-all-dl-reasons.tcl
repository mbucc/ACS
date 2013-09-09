# /www/download/admin/view-all-dl-reasons.tcl
ad_page_contract {
    display all reasons this file has been downloaded

    @param download_id the ID for this file
    @param scope
    @param group_id

    @author ahmeds@mit.edu
    @creation-date 4 Jan 2000
    @cvs-id view-all-dl-reasons.tcl,v 3.8.2.6 2000/09/24 22:37:17 kevin Exp
} {
    download_id:integer,notnull
    scope:optional
    group_id:optional,integer
}

# -----------------------------------------------------------------------------

ad_scope_error_check

set user_id [download_admin_authorize $download_id]

db_1row name_for_download "
select download_name
from downloads 
where download_id = :download_id"

append html "
<p>

<table cellpadding=3 border=1>
<tr>
<th  align=center>[ad_space 2] User Name [ad_space 2]  </th>
<th  align=center>[ad_space 2] Version[ad_space 2]  </th>
<th  align=center>[ad_space 2] Download Reason[ad_space 2] </th>
</tr>
"

db_foreach get_all_downloads "
select user_id, 
       entry_date, 
       ip_address, 
       version, 
       status, 
       log_id , 
       download_reasons, 
       dl.version_id
from   download_versions dv, 
       download_log dl
where  dl.version_id = dv.version_id
and    dv.download_id = :download_id
and    download_reasons is not null
order by entry_date desc" {


    if { [empty_string_p $user_id] } {
	set name_string "Anonymous"	
    } else {
	db_1row user_info "
	select email, first_names, last_name
	from users
	where user_id = :user_id "
	
	set name_string "<a href=\"mailto:$email\"><address>$first_names $last_name</address></a>"
	
    }

    append html "
    <tr>
    <td  align=left>$name_string</td>
    <td  align=center>[ad_decode $version "" "N/A" $version]</td>
    <td  align=left>[ad_space 2] $download_reasons</td>
     </tr>
    "

} if_no_rows {
    append html "
    There is no download reason information in the database about this particular download.
    "
} 

append html "
</table>
<p>
"

db_release_unused_handles

# -----------------------------------------------------------------------------

set page_title "View All Download Reasons of $download_name"

doc_return 200 text/html "
[ad_scope_header $page_title]
[ad_scope_page_title $page_title]
[ad_scope_context_bar_ws \
	[list "/download/index?[export_url_scope_vars]" "Download"] \
	[list "/download/admin/index?[export_url_scope_vars]" "Admin"] \
	[list "download-view?[export_url_scope_vars download_id]" "$download_name"] \
	[list "view-versions-report?[export_url_scope_vars download_id]" "Report"] \
	"Reasons"]

<hr>
[help_upper_right_menu]

<blockquote>
$html
</blockquote>
[ad_scope_footer]
"
