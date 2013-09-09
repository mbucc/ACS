# /www/download/admin/download-reason-view.tcl
ad_page_contract {
    displays download reason for this log id

    @param version_id the version being looked at
    @param log_id the ID for the download reason
    @param scope
    @param group_id
 
    @author ahmeds@mit.edu
    @creation-date 4 Jan 2000
    @cvs-id download-reason-view.tcl,v 3.7.2.6 2000/09/24 22:37:15 kevin Exp
} {
    log_id:integer,notnull
    version_id:integer,notnull
    scope:optional
    group_id:optional,integer
}

# -----------------------------------------------------------------------------

ad_scope_error_check


ad_scope_authorize $scope admin group_admin none

db_1row download_info_for_version "
select download_name , 
       version, 
       pseudo_filename, 
       dv.download_id as did
from   downloads d, 
       download_versions dv
where  d.download_id = dv.download_id
and    dv.version_id = :version_id"

db_1row download_reasons "
select download_reasons from download_log 
where log_id = :log_id"

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

doc_return 200 text/html "
[ad_scope_header $page_title]
[ad_scope_page_title $page_title]
[ad_scope_context_bar_ws \
	[list "/download/index?[export_url_scope_vars ]" "Download"] \
	[list "/download/admin/index?[export_url_scope_vars ]" "Admin"] \
	[list "download-view?[export_url_scope_vars download_id]" "$download_name"] \
	[list "view-versions?[export_url_scope_vars]&download_id=$did " "Versions"] \
	[list "view-one-version-report?[export_url_scope_vars version_id]" "Report"] \
	"Download Reason"]

<hr>

<blockquote>
$html
</blockquote>

[ad_scope_footer]
"
