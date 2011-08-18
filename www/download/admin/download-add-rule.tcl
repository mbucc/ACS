# /www/download/admin/download-add-rule.tcl
#
# Date:     01/04/2000
# Author :  ahmeds@mit.edu
# Purpose:  adds new downloadable file version
#
# $Id: download-add-rule.tcl,v 3.0.6.2 2000/05/18 00:05:15 ron Exp $
# -----------------------------------------------------------------------------

set_the_usual_form_variables
# maybe scope, maybe scope related variables (group_id)
# download_id 

ad_scope_error_check

set db [ns_db gethandle]
download_admin_authorize $db $download_id

set download_name [database_to_tcl_string $db \
	"select download_name from downloads where download_id = $download_id"]

set selection [ns_db select $db "
select max(version_id) as max_version_id , 
       version 
from   download_versions
where  download_id = $download_id
group  by version
order  by version desc"]

set labels [list "All Versions"]
set values [list ""]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { ![empty_string_p $version] } {
	lappend labels "Version $version"
    } else {
	lappend labels "Version (unspecified)"
    }
    lappend values $max_version_id
}

set select_options_html "
<option value=all>All Users
<option value=registered_users>Registered Users"

if { $scope == "group" } {
    append select_options_html "<option value=group_members>Group Members\n"
}

append html "

<form method=post action=download-add-rule-2.tcl>
[export_form_scope_vars download_id]

<input type=hidden name=new_rule_id value=\"[database_to_tcl_string $db "
select download_rule_id_sequence.nextval from dual"]\">

<table>

<tr>
<th align=right>Version:</th>
<td>[ns_htmlselect -labels $labels version_id $values null]</td>
</tr>

<tr>
<th align=right>Visibility:</th>
<td>
<select name=visibility> $select_options_html</select>
</td>
</tr>

<tr>
<th align=right>Availability:</th>
<td>
<select name=availability> $select_options_html</select>
</td>
</tr>

<tr>
<th align=right>Price:</th>
<td><input type=text name=price size=8></td>
</tr>

<tr>
<th align=right valign=top>&nbsp;<br>Currency:</th>
<td>[currency_widget $db "USD" "currency"]</td>
</tr>

<tr>
<td></td>
<td><input type=submit value=Submit>
</td>
</tr>

</table>
</form>
"

# -----------------------------------------------------------------------------

set page_title "Add Rule for $download_name"

ns_return 200 text/html "
[ad_scope_header $page_title $db]

<h2>$page_title</h2>

[ad_scope_context_bar_ws \
	[list "/download/" "Download"] \
	[list "/download/admin/" "Admin"] \
	[list "download-view.tcl?[export_url_scope_vars download_id]" "$download_name"]  \
	"Add Rule"]

<hr>

[help_upper_right_menu]

<blockquote>
$html
</blockquote>

[ad_scope_footer]
"
