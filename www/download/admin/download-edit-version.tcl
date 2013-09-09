# /www/download/admin/download-edit-version.tcl
ad_page_contract {
    edits information related to this version_id

    @param version_id the version being edited
    @param scope
    @param group_id

    @author ahmeds@mit.edu
    @creation-date 4 Jan 2000
    @cvs-id download-edit-version.tcl,v 3.9.2.6 2000/09/24 22:37:14 kevin Exp
} {
    version_id:integer,notnull
    scope:optional
    group_id:optional,integer
}

# -----------------------------------------------------------------------------

ad_scope_error_check


download_version_admin_authorize $version_id

page_validation {
    if {![db_0or1row version_info "
    select download_id,
           pseudo_filename,
           release_date,
           version,
           status,
           version_description,
           version_html_p
    from   download_versions 
    where  version_id = :version_id"]} {

	error "There is no file with version_id = $version_id."
    }
}

set item_list [ad_decode $scope "public" \
	"[list "All Users" "Registered Users" ]" \
	"[list "All Users" "Registered Users" "Group Members" ]"]

set value_list [ad_decode $scope "public" \
	"[list "all" "registered_users"]" \
	"[list "all" "registered_users" "group_members" ]" ]

if {[db_0or1row version_rules "
select visibility, 
       availability,
       price, 
       currency 
from   download_rules
where  version_id = :version_id"] } {

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
 
    if { [db_0or1row download_rules "
    select visibility, 
           availability,
           price, 
           currency 
    from   download_rules
    where  download_id = :download_id 
    and    version_id is null"]} {
    
	# found a rule for all versions of this download_id
	
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

db_1row download_name "
select download_name from downloads 
where download_id = :download_id"

doc_return 200 text/html "

[ad_scope_header $page_title]
[ad_scope_page_title $page_title]
[ad_scope_context_bar_ws \
	[list "/download/index?[export_url_scope_vars]" "Download"] \
	[list "/download/admin/index?[export_url_scope_vars]" "Admin"] \
	[list "download-view?[export_url_scope_vars download_id]" "$download_name"] \
	[list "view-versions?[export_url_scope_vars download_id]" "Versions"] \
	[list "view-one-version?[export_url_scope_vars version_id]" "One Version"] \
	"Edit"]

<hr>

<form method=get action=download-edit-version-2>
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
