# /www/download/admin/download-edit-version.tcl
#
# Date:     01/04/2000
# Author :  ahmeds@mit.edu
# Purpose:  edits information related to this version_id
#
# $Id: download-edit-version.tcl,v 3.1.2.2 2000/05/18 00:05:15 ron Exp $
# -----------------------------------------------------------------------------

set_the_usual_form_variables
# maybe scope, maybe scope related variables (group_id)
# version_id

ad_scope_error_check

set db [ns_db gethandle]
download_version_admin_authorize $db $version_id

set selection [ns_db 0or1row $db \
	"select * from download_versions where version_id = $version_id"]

set exception_count 0
set exception_text ""

if { [empty_string_p $selection] } {
    incr exception_count
    append exception_text "<li>There is no file with version_id = $version_id."
} else {
    set_variables_after_query
}

if { $exception_count > 0 } {
    ad_scope_return_complaint $exception_count $exception_text $db
    return
}

set selection [ns_db 0or1row $db "
select visibility, 
       availability,
       price, 
       currency 
from   download_rules
where  version_id = $version_id"]

set item_list [ad_decode $scope "public" \
	"[list "All Users" "Registered Users" ]" \
	"[list "All Users" "Registered Users" "Group Members" ]"]

set value_list [ad_decode $scope "public" \
	"[list "all" "registered_users"]" \
	"[list "all" "registered_users" "group_members" ]" ]

set counter 0

if { ![empty_string_p $selection] } {
    # found a rule for this specific version_id
    set_variables_after_query

    set rule_html "
    <tr>
    <th align=right>Visibility:</th>
    <td><select name=visibility>
    [ad_generic_optionlist $item_list $value_list $visibility]
    </select>
    </td>
    </tr>

    <tr>
    <th align=right>Availability:</th>
    <td><select name=availability>
    [ad_generic_optionlist $item_list $value_list $availability]
    </select>
    </td>
    </tr>
    "    

    if { ![empty_string_p $price] } {
	append rule_html "
	<tr>
	<th align=right>Price:</th>
	<td>$price $currency</td>
	</tr>
	"
    }
} else {    
    
    # no version-specific rule, look for a rule for all versions of this download_id
 
    set selection [ns_db 0or1row $db "
    select visibility, 
           availability,
           price, 
           currency 
    from   download_rules
    where  download_id = $download_id 
    and    version_id is null"]
    
    if { ![empty_string_p $selection] } {
	# found a rule for all versions of this download_id
	set_variables_after_query
	
	set rule_html "
	<tr>
	<th align=right>Visibility:</th>
	<td><select name=visibility>
	[ad_generic_optionlist $item_list  $value_list  $visibility]
	</select>
	</td>
	</tr>

	<tr>
	<th align=right>Availability:</th>
	<td><select name=availability>
	[ad_generic_optionlist $item_list  $value_list  $availability]
	</select>
	</td>
	</tr>
	"    

	if { ![empty_string_p $price] } {
	    append rule_html "
	    <tr>
	    <th align=right>Price:</th>
	    <td>$price $currency</td>
	    </tr>
	    "
	}
    } else {
	# no  rule for all version of this download_id
	set rule_html ""
    }
}

# -----------------------------------------------------------------------------

set page_title "Edit Version Info"

set download_name [database_to_tcl_string $db \
	"select download_name from downloads where download_id = $download_id"]

ns_return 200 text/html "

[ad_scope_header $page_title $db]
[ad_scope_page_title $page_title $db]
[ad_scope_context_bar_ws \
	[list "/download/" "Download"] \
	[list "/download/admin/" "Admin"] \
	[list "download-view.tcl?[export_url_scope_vars download_id]" "$download_name"] \
	[list "view-versions.tcl?[export_url_scope_vars download_id]" "Versions"] \
	[list "view-one-version.tcl?[export_url_scope_vars version_id]" "One Version"] \
	"Edit"]

<hr>

<form method=get action=download-edit-version-2.tcl>
[export_form_scope_vars version_id]

<blockquote>
<table cellpadding=3>

<tr>
<th align=right>Pseudo File Name:</th>
<td>
<input type=text size=30 MAXLENGTH=100 name=pseudo_filename [export_form_value pseudo_filename]>
</td>
</tr>

<tr>
<th align=right>Version:</th>
<td><input type=text size=5 name=version MAXLENGTH=10 value=$version>
</td>
</tr>

<tr>
<th align=right>Release Date:
<td>[ad_dateentrywidget release_date $release_date]
</td>
</tr>

<tr>
<th align=right>Status:</th>
<td><select name=status>
[ad_generic_optionlist {"Promote" "Offer If Asked" "Removed"  }  {"promote" "offer_if_asked" "removed" } $status]
</select>
</td>
</tr>

$rule_html

<tr>
<th align=right valign=top>&nbsp;<br>Version Description:</th>
<td>
<textarea name=version_description cols=40 rows=5 wrap=soft>[ns_quotehtml $version_description]</textarea>
</td>
</tr>

<tr>
<th align=right>Text above is:</th>
<td>
<select name=version_html_p>
 [ad_generic_optionlist {"Plain Text" "HTML"} {"f" "t"} $version_html_p]
</select>
</td>
</tr>

<tr>
<td></td>
<td><input type=submit value=Update></td>
</tr>
</table>
</blockquote>
</form>

[ad_scope_footer]
"
