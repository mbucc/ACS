# $Id: view-one-version.tcl,v 3.0 2000/02/06 03:16:42 ron Exp $
# File:     /admin/download/view-one-version.tcl
# Date:     01/04/2000
# Author :  ahmeds@mit.edu
# Purpose:  adds new downloadable file version

set_the_usual_form_variables
# version_id

set db [ns_db gethandle]
download_version_admin_authorize $db $version_id

set selection [ns_db 0or1row $db "
select * 
from download_versions
where version_id=$version_id"]

set exception_count 0
set exception_text ""

if { [empty_string_p $selection] } {
    incr exception_count
    append exception_text "<li>There is no file with the given version id."
} else {
    set_variables_after_query
}

if { $exception_count >0 } {
    ad_return_complaint $exception_count $exception_text 
    return
}

set selection [ns_db 0or1row $db "
select visibility, price, currency 
from download_rules
where version_id=$version_id"]
 
set counter 0

if { ![empty_string_p $selection] } {
    # found a rule for this specific version_id
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


ReturnHeaders 

set page_title "View One Version"

set download_name [database_to_tcl_string $db "
select download_name
from downloads 
where download_id = $download_id"]

ns_write "
[ad_admin_header $page_title ]
<h2>$page_title</h2>
[ad_admin_context_bar [list "index.tcl?[export_url_vars]" "Download"] [list "download-view.tcl?[export_url_vars download_id]" "$download_name"] [list "view-versions.tcl?[export_url_vars download_id]" "Versions"] $page_title]

<hr>
[help_upper_right_menu]
"

append html "

<p>

<table cellpadding=3>

<tr><th  align=left>Pseudo File Name [ad_space 5] </th>
<td>$pseudo_filename [ad_space 1] 
</td></tr>

<tr><th  align=left>Version ID</th>
<td>$version_id</td></tr>

<tr><th  align=left>Download ID</th>
<td>$download_id</td></tr>

<tr><th  align=left>Version</th>
<td>$version</td></tr>

<tr><th align=left >Release Date <td>[util_AnsiDatetoPrettyDate $release_date ]
</tr>

<tr><th  align=left>Creation User ID</th>
<td>$creation_user</td></tr>

<tr><th  align=left>Creation Date</th>
<td>[util_AnsiDatetoPrettyDate $creation_date]</td></tr>

<tr><th  align=left>Creation IP Address</th>
<td>$creation_ip_address</td></tr>

<tr><th  align=left>Status</th>
<td>[ad_decode $status "promote" "Promote" "offer_if_asked" "Offer If Asked" "Removed"]</td></tr>

$rule_html

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
    <li><a href=\"view-one-version-report.tcl?[export_url_vars version_id]\">Download History</a> :  $history_count download(s) between 
    [util_AnsiDatetoPrettyDate $min_entry_date] and [util_AnsiDatetoPrettyDate $max_entry_date] 
    "
}

ns_write "
<blockquote>
$html
</blockquote>
<p>
[ad_admin_footer]
"
