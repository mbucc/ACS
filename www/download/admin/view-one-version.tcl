# /www/download/admin/view-one-version.tcl
#
# Date:     01/04/2000
# Author :  ahmeds@mit.edu
# Purpose:  adds new downloadable file version
#
# $Id: view-one-version.tcl,v 3.0.4.2 2000/05/18 00:05:17 ron Exp $
# -----------------------------------------------------------------------------

set_the_usual_form_variables
# maybe scope, maybe scope related variables (group_id)
# version_id

ad_scope_error_check

set db [ns_db gethandle]
download_version_admin_authorize $db $version_id

set selection [ns_db 0or1row $db "
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
where  dv.version_id = $version_id
and    dv.creation_user = u.user_id"]

set exception_count 0
set exception_text ""

if { [empty_string_p $selection] } {
    incr exception_count
    append exception_text "<li>There is no file with the given version id."
} else {
    set_variables_after_query
}

if { $exception_count >0 } {
    ad_scope_return_complaint $exception_count $exception_text $db
    return
}

set selection [ns_db 0or1row $db "
select visibility, 
       availability,
       price, 
       currency 
from   download_rules
where  version_id=$version_id"]
 
set counter 0

if { ![empty_string_p $selection] } {
    # found a rule for this specific version_id
    set_variables_after_query

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
 
    set selection [ns_db 0or1row $db "
    select visibility, price, currency 
    from download_rules
    where download_id = $download_id 
    and version_id is null"]
    
    if { ![empty_string_p $selection] } {
	# found a rule for all versions of this download_id
	set_variables_after_query
	
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

set download_name [database_to_tcl_string $db "
select download_name from downloads where download_id = $download_id"]

append html "

<p>
\[ <a href=\"download-edit-version.tcl?[export_url_scope_vars version_id]\">Edit</a> |
 <a href=\"download-remove-version.tcl?[export_url_scope_vars version_id]\">Remove</a> \]
<p>

<table cellpadding=3>

<tr>
<th align=left>Pseudo File Name [ad_space 5] </th>
<td>$pseudo_filename [ad_space 1] 
</td></tr>

<tr><th  align=left>Version</th>
<td>$version</td></tr>

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

set history_count [database_to_tcl_string $db "select count(*) from download_log where version_id = $version_id "]

if { $history_count > 0 } {
    
    set selection [ns_db 1row $db "
    select max(entry_date) as max_entry_date, min(entry_date) as min_entry_date
    from download_log
    where version_id = $version_id "]
    
    set_variables_after_query
    
    append html "
    <li><a href=\"view-one-version-report.tcl?[export_url_scope_vars version_id]\">Download History</a> :  $history_count download(s) between 
    [util_AnsiDatetoPrettyDate $min_entry_date] and [util_AnsiDatetoPrettyDate $max_entry_date] 
    "
}

# -----------------------------------------------------------------------------

set page_title "One Version"

ns_return 200 text/html "
[ad_scope_admin_header $page_title $db]

<h2>$page_title</h2>

[ad_scope_context_bar_ws \
	[list "/download/" "Download"] \
	[list "/download/admin/" "Admin"] \
	[list "download-view.tcl?[export_url_scope_vars download_id]" "$download_name"] \
	[list "view-versions.tcl?[export_url_scope_vars download_id]" "Versions"] \
	$page_title]

<hr>
[help_upper_right_menu]

<blockquote>
$html
</blockquote>
<p>
[ad_scope_footer]
"



