# /www/download/admin/view-all-dl-version-reasons.tcl
ad_page_contract {
    displays all reasons for this download version 

    @param version_id the version we are viewing information about
    @param scope
    @param group_id

    @author ahmeds@mit.edu
    @creation-date 4 Jan 2000
    @cvs-id view-all-dl-version-reasons.tcl,v 3.7.2.6 2000/09/24 22:37:17 kevin Exp
} {
    version_id:integer,notnull
    scope:optional
    group_id:optional,integer
}

# -----------------------------------------------------------------------------

ad_scope_error_check

download_version_admin_authorize $version_id

page_validation {
    if { ![db_0or1row version_info "
    select download_id,
           pseudo_filename
    from   download_versions
    where  version_id = :version_id"]} {

	error "There is no file with the given version id."

    }
}

db_1row download_name "
select download_name
from   downloads 
where  download_id = :download_id"


append html "
<p>

<table cellpadding=3 border=1>
<tr>
<th  align=center>[ad_space 2] User Name [ad_space 2]  </th>
<th  align=center>[ad_space 2] Download Reason[ad_space 2] </th>
</tr>
"

db_foreach download_reasons "
select user_id, 
       download_reasons, 
       dl.version_id as version_id
from   download_versions dv, 
       download_log dl
where  dl.version_id = dv.version_id
and    dv.version_id = :version_id
and    download_reasons is not null
order by entry_date desc" {

    if { [empty_string_p $user_id] } {
	set name_string "Anonymous"	
    } else {
	db_1row user_info "
	select email, first_names, last_name
	from users
	where user_id = :user_id"
	
	set name_string "<a href=\"mailto:$email\"><address>$first_names $last_name</address></a>"
	
    }

    append html "
    <tr>
    <td  align=left>$name_string</td>
    <td  align=left>[ad_space 2] $download_reasons</td>
     </tr>
    "

} if_no_rows {
    append html "
    <i>There is no download reason information in the database about 
    this particular download version.</i>
    "
}

append html "
</table>
<p>
"


# -----------------------------------------------------------------------------

set page_title "View All Reasons for Downloading $pseudo_filename"

doc_return 200 text/html "
[ad_scope_header $page_title]
[ad_scope_page_title $page_title]
[ad_scope_context_bar \
	[list "/download/index?[export_url_scope_vars]" "Download"] \
	[list "/download/admin/index?[export_url_scope_vars]" "Admin"] \
	[list "download-view?[export_url_scope_vars download_id]" "$download_name"] \
	[list "view-versions?[export_url_scope_vars download_id]" "Vesrions"] \
	[list "view-one-version?[export_url_scope_vars version_id]" "One Version"] \
	[list "view-one-version-report?[export_url_scope_vars version_id]" "Report"] \
	"Reasons" ]

<hr>
[help_upper_right_menu]

<blockquote>
$html
</blockquote>
[ad_scope_footer]
"
