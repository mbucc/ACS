# /www/download/admin/view-one-version-report.tcl
ad_page_contract {
    displays summary of this version ( who downloaded for what reason)

    @param version_id the ID of the version we are interested
    @param scope
    @param group_id

    @author ahmeds@mit.edu
    @creation-date 4 Jan 2000
    @cvs-id view-one-version-report.tcl,v 3.11.2.6 2000/09/24 22:37:18 kevin Exp
} {
    version_id:integer,notnull
    scope:optional
    group_id:optional,integer
}

# -----------------------------------------------------------------------------

ad_scope_error_check

download_version_admin_authorize $version_id

db_1row download_info_for_version "
select download_name , 
       version, 
       dv.download_id as did
from   downloads d, 
       download_versions dv
where  d.download_id = dv.download_id
and    dv.version_id = :version_id"


set email_count [db_string email_count "
select count(distinct u.email)
from   download_versions dv, download_log dl, users u
where  dl.version_id = dv.version_id
and    dl.user_id = u.user_id
and    dv.version_id = :version_id"]

if { $email_count > 0 } {
    append html "
    <li><a href=\"spam-all-version-downloaders?[export_url_scope_vars version_id]\">Spam All Downloaders</a>
    "
} 

set reason_count [db_string reason_count "
select count (*) 
from   download_versions dv, download_log dl
where  dl.version_id = dv.version_id
and    dv.version_id = :version_id
and    download_reasons is not null"]

if { $reason_count > 0 } {
    append html "
    <li><a href=\"view-all-dl-version-reasons?[export_url_scope_vars version_id]\">View All Download Reasons</a>
    "
}

append html "
<p>
<table cellpadding=3 border=1>
<tr>
<th  align=center>[ad_space 1] User Name [ad_space 1]  </th>
<th  align=center>[ad_space 1] Email [ad_space 1]  </th>
<th  align=center>[ad_space 1] Download Date[ad_space 1]  </th>
<th  align=center>[ad_space 1] IP Address[ad_space 1]  </th>
<th  align=center>[ad_space 1] Version[ad_space 1]  </th>
<th  align=center>[ad_space 1] Status[ad_space 1]  </th>
<th  align=center>[ad_space 1] Download Reason[ad_space 1]  </th>
<th  align=center>Remove </th>
</tr>
"

db_foreach user_downloads "
select user_id, 
       entry_date, 
       ip_address, 
       version, 
       status, 
       log_id , 
       download_reasons
from   download_versions dv, 
       download_log dl
where  dl.version_id = dv.version_id
and    dv.version_id = :version_id
order by entry_date desc" {


    if { [empty_string_p $user_id] } {
	set email_string "Unavailable"
	set name_string "Anonymous"	
    } else {
	db_1row user_info "
	select email, first_names, last_name
	from users
	where user_id = :user_id "
	
	set email_string "<a href=\"mailto:$email\"><address>$email</address></a>"
	set name_string "$first_names $last_name"	
    }
    

    set dl_reason_html [ad_decode $download_reasons "" None "<a href=download-reason-view?[export_url_scope_vars log_id version_id]>view</a>"]

    set return_url "view-one-version-report?[export_url_scope_vars version_id]"

    append html "
    <tr>
    <td  align=left>$name_string</td>
    <td  align=left>$email_string</td>
    <td  align=center>[util_AnsiDatetoPrettyDate $entry_date]</td>
    <td  align=center>$ip_address</td>
    <td  align=center>[ad_decode $version "" "N/A" $version]</td>
    <td  align=left>$status</td>
    <td  align=center>$dl_reason_html</td>
    <td  align=center><a href=log-entry-remove?[export_url_scope_vars log_id return_url]>remove</a></td>
     </tr>
    "
} if_no_rows {
    append html "
    <i>There is no log information in the database about this 
    particular download.</i>
    "
}

append html "
</table>
<p>
"

# -----------------------------------------------------------------------------

set page_title "Download Report of $download_name version $version"

doc_return 200 text/html "
[ad_scope_header $page_title]
[ad_scope_page_title $page_title]
[ad_scope_context_bar \
	[list "/download/index?[export_url_scope_vars]" "Download"] \
	[list "/download/admin/index?[export_url_scope_vars]" "Admin"] \
	[list "download-view?[export_url_scope_vars ]&download_id=$did " "$download_name"] \
	[list "view-versions?[export_url_scope_vars]&download_id=$did " "Versions"] \
	[list "view-one-version?[export_url_scope_vars version_id]" "One Version"] \
	"View Report"]

<hr>
[help_upper_right_menu]

<blockquote>
$html
</blockquote>
[ad_scope_footer]
"
