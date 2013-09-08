ad_page_contract { 
    Edits information for a version of a package.
    
    @param version_id The id of the package to process.
    @author Jon Salz [jsalz@arsdigita.com]
    @date 9 May 2000
    @cvs-id version-edit.tcl,v 1.4.2.3 2000/07/21 03:55:46 ron Exp
} {
    {version_id:integer}
}

db_1row apm_all_version_info {
    select version_id, package_key, package_id, package_url, package_name, version_name, version_url,
    summary, description_format, description, distribution, release_date, vendor, vendor_url, package_group,
    enabled_p, installed_p, tagged_p, imported_p, data_model_loaded_p, activation_date, tarball_length, 
    deactivation_date, distribution_url, distribution_date
    from apm_package_version_info where version_id = :version_id
}

set includes [db_list apm_all_includes {
    select version_url from apm_package_includes where version_id = :version_id
}]

doc_body_append "[apm_header -form "action=\"version-edit-2.tcl\" method=post" [list "version-view.tcl?version_id=$version_id" "$package_name $version_name"] "Edit a Version"]

"

# If the version name is incorporated into the version URL (it will almost always be!)
# then generate some JavaScript to automatically update the version URL when the
# version name changes.

set version_name_index [string first $version_name $version_url]
if { $version_name_index >= 0 } {
    set version_url_prefix [string range $version_url 0 [expr { $version_name_index - 1 }]]
    set version_url_suffix [string range $version_url [expr { $version_name_index + [string length $version_name] }] end]

    doc_body_append "
<script language=javascript>
function updateVersionURL() {
    var form = document.forms\[0\];
    form.version_url.value = '$version_url_prefix' + form.version_name.value + '$version_url_suffix';
}
</script>
"

    set version_name_on_change "onChange=\"updateVersionURL()\""
} else {
    set version_name_on_changed ""
}

doc_body_append "
<script language=javascript>
function checkMailto(element) {
    // If it looks like an email address without a mailto: (contains an @ but
    // no colon) then prepend 'mailto:'.
    if (element.value.indexOf('@') >= 0 && element.value.indexOf(':') < 0)
        element.value = 'mailto:' + element.value;
}
</script>

[export_form_vars version_id]

<table>

<tr>
  <th align=right nowrap>Package Key:</th>
  <td><tt>$package_key</tt></td>
</tr>
<tr>
  <th align=right nowrap>Package URL:</th>
  <td>$package_url</td>
</tr>

<tr>
  <th align=right nowrap>Package Name:</th>
  <td><input name=package_name size=30 value=\"$package_name\"></td>
</tr>

<tr>
  <td></td>
  <td>To create a new version of the package, type a new version number and
update the version URL accordingly. Leave the version name and URL alone to
edit the information regarding existing version of the package.</td>
</tr>

<tr>
  <th align=right nowrap>Version:</th>
  <td><input name=version_name size=10 value=\"$version_name\" $version_name_on_change>
</td>
</tr>

<tr>
  <th align=right nowrap>Version URL:</th>
  <td><input name=version_url size=60 value=\"$version_url\"></td>
</tr>

<tr valign=top>
  <th align=right><br>Summary:</th>
  <td><textarea name=summary cols=60 rows=2 wrap=soft>[ns_quotehtml $summary]</textarea></td>
</tr>

<tr valign=top>
  <th align=right><br>Description:</th>
  <td><textarea name=description cols=60 rows=5 wrap=soft>[ns_quotehtml $description]</textarea><br>
This description is <select name=description_format>
<option value=text/html [ad_decode $description_format "text/plain" "" "selected"]>HTML-formatted.
<option value=text/plain [ad_decode $description_format "text/plain" "selected" ""]>plain text.
</select>
</td>
</tr>
"

# Build a list of owners. Ensure that there are at least two.
set owners [db_list_of_lists apm_all_owners {
    select owner_name, owner_url from apm_package_owners where version_id = :version_id
}]
if { [llength $owners] == 0 } {
    set owners [list [list "" ""]]
}

# Add an extra one, so an arbitrary number of owners can be assigned to the package.
lappend owners [list "" ""]

set counter 0
foreach owner_info $owners {
    set owner_name [lindex $owner_info 0]
    set owner_url [lindex $owner_info 1]
    incr counter

    if { $counter <= 3 } {
	set prompt "[lindex { "" Primary Secondary Tertiary } $counter] Owner"
    } else {
	set prompt "Owner #$counter"
    }

    doc_body_append "
<tr>
  <th align=right nowrap>$prompt:</th>
  <td><input name=owner_name_$counter size=30 value=\"$owner_name\"></td>
</tr>
<tr>
  <th align=right nowrap>$prompt URL:</th>
  <td><input name=owner_url_$counter size=30 value=\"$owner_url\" onChange=\"checkMailto(this)\"></td>
</tr>
"
}

doc_body_append "
<tr>
  <th align=right nowrap>Vendor:</th>
  <td><input name=vendor size=30 value=\"$vendor\"></td>
</tr>
<tr>
  <th align=right nowrap>Vendor URL:</th>
  <td><input name=vendor_url size=60 value=\"$vendor_url\"></td>
</tr>

<tr valign=top>
  <th align=right nowrap><br>Included Packages:</th>
  <td><textarea name=includes rows=5 cols=60>[ns_quotehtml [join $includes "\n"]]</textarea>
<br><i>(specify URLs, one per line)</i></td>
</tr>

<tr>
  <td></td>
  <td>
    <table><tr valign=baseline><td><input type=checkbox name=install_p value=1 checked></td><td>
Write this new information to the package information file, <tt>packages/$package_key/$package_key.info</tt> (i.e., mark this new version as installed).</td></tr></table>
  </td>
</tr>

<tr>
  <td colspan=2 align=center><br>
<input type=submit value=\"Save Information\">
</td>
</tr>

</table>

[ad_footer]
"

