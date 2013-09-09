# /www/download/admin/download-add-rule.tcl
ad_page_contract {
    add a rule for downloading a file

    @param download_id the ID of the file to add a rule for
    @param scope
    @param group_id

    @author ahmeds@mit.edu
    @creation-date 4 Jan 2000
    @cvs-id download-add-rule.tcl,v 3.10.2.6 2000/09/24 22:37:14 kevin Exp
} {
    download_id:integer,notnull
    scope:optional
    group_id:optional
}

# -----------------------------------------------------------------------------

ad_scope_error_check


download_admin_authorize $download_id

db_1row name_for_download "
select download_name from downloads 
where download_id = :download_id"

set labels [list "All Versions"]
set values [list ""]

db_foreach download_versions "
select max(version_id) as max_version_id , 
       version 
from   download_versions
where  download_id = $download_id
group  by version
order  by version desc" {

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

# -----------------------------------------------------------------------------

set page_title "Add Rule for $download_name"

doc_return 200 text/html "
[ad_scope_header $page_title]

<h2>$page_title</h2>

[ad_scope_context_bar_ws \
	[list "/download/index?[export_url_scope_vars]" "Download"] \
	[list "/download/admin/index?[export_url_scope_vars]" "Admin"] \
	[list "download-view?[export_url_scope_vars download_id]" "$download_name"]  \
	"Add Rule"]

<hr>

[help_upper_right_menu]

<blockquote>

<form method=post action=download-add-rule-2>
[export_form_scope_vars download_id]

<input type=hidden name=new_rule_id value=\"[db_string next_rule_id "
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
<td>[currency_widget "USD" "currency"]</td>
</tr>

<tr>
<td></td>
<td><input type=submit value=Submit>
</td>
</tr>

</table>
</form>

</blockquote>

[ad_scope_footer]
"
