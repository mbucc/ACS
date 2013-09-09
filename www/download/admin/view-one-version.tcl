# /www/download/admin/view-one-version.tcl
ad_page_contract {
    add new downloadable file version

    @param version_id
    @param scope
    @param group_id

    @author ahmeds@mit.edu
    @creation-date 4 Jan 2000
    @cvs-id view-one-version.tcl,v 3.12.2.6 2000/09/24 22:37:18 kevin Exp
} {
    version_id:integer,notnull
    scope:optional
    group_id:optional
}

# -----------------------------------------------------------------------------

ad_scope_error_check

download_version_admin_authorize $version_id

if { ![db_0or1row info_for_one_version "
select dv.version_id,
       dv.download_id,
       dv.release_date,
       dv.pseudo_filename,
       dv.version,
       dv.version_description,
       dv.version_html_p,
       dv.status,
       dv.creation_date,
       dv.creation_ip_address,
       u.first_names ||' '|| u.last_name as full_name
from   download_versions dv,
       users u
where  dv.version_id = :version_id
and    dv.creation_user = u.user_id"] } {

    ad_scope_return_complaint 1 "<li>There is no file with the given version id."
    return
}

if {[db_0or1row version_download_rules "
select visibility, 
       availability,
       price, 
       currency 
from   download_rules
where  version_id=:version_id"]} {
 
    # found a rule for this specific version_id

    set rule_html "
    <tr><th align=left>Visibility</th>
    <td>[ad_decode $visibility "all" "All" "group_members" "Group Members" "Registered Users"]</td></tr>

    <tr><th align=left>Availability</th>
    <td>[ad_decode $availability "all" "All" "group_members" "Group Members" "Registered Users"]</td></tr>
    "    

    if { ![empty_string_p $price] } {
	append rule_html "
	<tr><th  align=left>Price</th>
	<td>$price $currency</td></tr>
	"
    }
} else {    
    
    # no version specific rule, look for a rule for all version of this download_id
 
    if {[db_0or1row download_rules "
    select visibility, price, currency 
    from download_rules
    where download_id = $download_id 
    and version_id is null"]} {
    
	# found a rule for all versions of this download_id
	
	set rule_html "
	<tr><th  align=left>Visibility</th>
	<td>[ad_decode $visibility "all" "All" "group_members" "Group Members" "Registered Users"]</td></tr>
	"    
	if { ![empty_string_p $price] } {
	    append rule_html "
	    <tr><th  align=left>Price</th>
	    <td>$price $currency</td></tr>
	    "
	}
    } else {
	# no  rule for all version of this download_id
	set rule_html ""
    }
}

set version_description_string [ad_decode $version_description "" None $version_description]

set version_html_string [ad_decode $version_description "" "" "<tr><th  align=left>Text above is <td>[ad_decode $version_html_p t HTML "Plain Text"]</tr>"]

set page_title "View One Version"

if { [db_0or1row download_file "
select d.download_name as download_name,
       d.scope as file_scope, 
       d.group_id as gid, 
       d.directory_name as directory
from   downloads d
where  download_id = :download_id"] } {

    
    if {$file_scope == "public"} {
	set full_filename "[ad_parameter DownloadRoot download]$directory/$version_id.file"
    } else {
	# scope is group
	# download_authorize $did
	set full_filename "[ad_parameter DownloadRoot download]groups/$gid/$directory/$version_id.file"
    }

}
    

append html "

<p>
\[ <a href=\"download-edit-version?[export_url_scope_vars version_id]\">Edit</a> |
 <a href=\"download-remove-version?[export_url_scope_vars version_id]\">Remove</a> \]
<p>

<table cellpadding=3>

<tr>
<th align=left>Pseudo File Name [ad_space 5] </th>
<td>$pseudo_filename [ad_space 1] 
</td></tr>

<tr><th  align=left>Version</th>
<td>[ad_decode $version "" "N/A" $version]</td></tr>

<tr><th  align=left>Filesize</th>
<td>[expr [file size $full_filename] / 1000]k</td></tr>

<tr><th align=left >Release Date <td>[util_AnsiDatetoPrettyDate $release_date ]
</tr>

<tr><th align=left>Created by</th>
<td>$full_name</td></tr>

<tr><th  align=left>Creation Date</th>
<td>[util_AnsiDatetoPrettyDate $creation_date]</td></tr>

<tr><th  align=left>Creation IP Address</th>
<td>$creation_ip_address</td></tr>

<tr><th  align=left>Status</th>
<td>[ad_decode $status "promote" "Promote" "offer_if_asked" "Offer If Asked" "Removed"]</td></tr>

$rule_html

<tr><th valign=top align=left>Version Description</th>
<td> $version_description_string </td></tr>

$version_html_string

</table>

<p>

"

set history_count [db_string history_count "
select count(*) from download_log 
where version_id = :version_id "]

if { $history_count > 0 } {
    
    db_1row log_dates "
    select max(entry_date) as max_entry_date, min(entry_date) as min_entry_date
    from download_log
    where version_id = :version_id "
    
    append html "
    <li><a href=\"view-one-version-report?[export_url_scope_vars version_id]\">Download History</a> :  $history_count download(s) between 
    [util_AnsiDatetoPrettyDate $min_entry_date] and [util_AnsiDatetoPrettyDate $max_entry_date] 
    "
}

# -----------------------------------------------------------------------------

set page_title "One Version"

doc_return 200 text/html "
[ad_scope_admin_header $page_title]

<h2>$page_title</h2>

[ad_scope_context_bar_ws \
	[list "/download/index?[export_url_scope_vars]" "Download"] \
	[list "/download/admin/index?[export_url_scope_vars]" "Admin"] \
	[list "download-view?[export_url_scope_vars download_id]" "$download_name"] \
	[list "view-versions?[export_url_scope_vars download_id]" "Versions"] \
	$page_title]

<hr>
[help_upper_right_menu]

<blockquote>
$html
</blockquote>
<p>
[ad_scope_footer]
"

