# /www/download/admin/download-view.tcl
ad_page_contract {
    Admin view for a download item

    @param download_id the item to view
    @param scope
    @param group_id
    
    @author ahmeds@mit.edu
    @creation-date 4 Jan 2000
    @cvs-id download-view.tcl,v 3.10.2.6 2000/09/24 22:37:16 kevin Exp
} {
    download_id:integer,notnull
    scope:optional
    group_id:optional
}

# -----------------------------------------------------------------------------

ad_scope_error_check

set user_id [download_admin_authorize $download_id]

db_1row name_for_download "
select download_name, 
       directory_name, 
       description
from   downloads 
where  download_id = :download_id"

# now we have the values from the database.

set description_string [ad_decode $description "" None $description]

append page_content "

<p>
\[ <a href=\"download-edit?[export_url_scope_vars download_id]\">Edit</a> |   
   <a href=\"download-remove?[export_url_scope_vars download_id]\">Remove</a> \]

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
<a href=download-add-version?[export_url_scope_vars download_id]>Upload New Version</a>
"

set counter [db_string num_versions "
select count(*) from download_versions 
where download_id = :download_id"]

if { $counter > 0 } {
    append page_content "
    <li><a href=\"view-versions?[export_url_scope_vars download_id]\">View All Versions</a>"
}

append page_content "<li><a href=\"download-add-rule?[export_url_scope_vars download_id]\">Add Rule</a>"

set counter [db_string num_logs "
select count(*)
from   download_versions dv, 
       download_log dl
where  dl.version_id  = dv.version_id
and    dv.download_id = :download_id"]

if { $counter > 0 } {
    db_1row log_dates "
    select max(entry_date) as max_entry_date, 
           min(entry_date) as min_entry_date 
    from   download_versions dv, 
           download_log dl
    where  dl.version_id  = dv.version_id
    and    dv.download_id = :download_id"
    
    append page_content "
    <p>
    <li>
    <a href=\"view-versions-report?[export_url_scope_vars download_id]\">Download History</a>: 
    [util_commify_number $counter] download(s) between 
    [util_AnsiDatetoPrettyDate $min_entry_date] and [util_AnsiDatetoPrettyDate $max_entry_date]
    " 
}

# -----------------------------------------------------------------------------

set page_title "View the entry for $download_name"

set page_header "
[ad_scope_header $page_title]
[ad_scope_page_title $page_title]
[ad_scope_context_bar_ws \
	[list "/download/index?[export_url_scope_vars]" "Download"] \
	[list "/download/admin/index?[export_url_scope_vars]" "Admin"] \
	"$download_name"]

<hr>
"



doc_return 200 text/html "
$page_header
<blockquote>
$page_content
</blockquote>

[ad_scope_footer]"
