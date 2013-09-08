ad_page_contract {
    Adds a package to the package manager.
    @author Jon Salz [jsalz@arsdigita.com]
    @date 17 April 2000
    @cvs-id package-add.tcl,v 1.3.2.4 2000/07/21 03:55:43 ron Exp
} {
}

set user_id [ad_get_user_id]

db_1row apm_get_name { 
    select first_names || ' ' || last_name user_name, email from users where user_id = :user_id
}
db_release_unused_handles

doc_body_append "[apm_header -form "action=package-add-2.tcl method=post" "Add a New Package"]

<script language=javascript>
function updateURLs() {
    // Update the package and version URL, if the package key and/or version name change.
    var form = document.forms\[0\];
    form.package_url.value = 'http://software.arsdigita.com/packages/' + form.package_key.value;
    if (form.version_name.value != '')
        form.version_url.value = form.package_url.value + '-' + form.version_name.value + '.apm';
}
</script>

<script language=javascript>
function checkMailto(element) {
    // If it looks like an email address without a mailto: (contains an @ but
    // no colon) then prepend 'mailto:'.
    if (element.value.indexOf('@') >= 0 && element.value.indexOf(':') < 0)
        element.value = 'mailto:' + element.value;
}
</script>

<table>

<tr>
  <td></td>
  <td>Select a package key for your package. This is a unique, short identifier
for your package containing only letters, numbers, and hyphens (e.g., <tt>address-book</tt>
for the address book package or <tt>apm</tt> for the ArsDigita Package Manager).
Files for your package will be placed in a directory with this name.</td>
</tr>

<tr>
  <th align=right nowrap>Package Key:</th>
  <td><input name=package_key size=30 onChange=\"updateURLs()\"></td>
</tr>

<tr>
  <td></td>
  <td>Select a short, human-readable name for your package, e.g., \"Address Book\" or
\"ArsDigita Package Manager.\"
</tr>

<tr>
  <th align=right nowrap>Package Name:</th>
  <td><input name=package_name size=30></td>
</tr>

<tr>
  <td></td>
  <td>Now pick a canonical URL for your package. Right now this is used only to uniquely
identify the package, and the default (placed here as soon as you type in a
package key) should always be correct.</td>
</tr>

<tr>
  <th align=right nowrap>Package URL:</th>
  <td><input name=package_url size=60></td>
</tr>

<tr>
  <td></td>
  <td>Select an initial version number for the package. By convention, this is
<tt>0.1d</tt> if you are just starting to create your package, or
<tt>0.5</tt> if you are creating your package from ACS 3.2 code.
</tr>

<tr>
  <th align=right nowrap>Initial Version:</th>
  <td><input name=version_name size=10 onChange=\"updateURLs()\"></td>
</tr>

<tr>
  <td></td>
  <td>Pick a canonical URL for the initial version of the package. For now, the default
will always be correct.</td>
</tr>

<tr>
  <th align=right nowrap>Version URL:</th>
  <td><input name=version_url size=60></td>
</tr>

<tr>
  <td></td>
  <td>Type a brief, one-sentence-or-less summary of the functionality of your package. (A sentence
fragment is fine.)
In general, this should be similar to the text next to a on the
<a href=\"/doc/\">developer documentation page</a>. The summary should begin
with a capital letter and end with a period.
</td>
</tr>

<tr valign=top>
  <th align=right><br>Summary:</th>
  <td><textarea name=summary cols=60 rows=2 wrap=soft></textarea></td>
</tr>

<tr>
  <td></td>
  <td>Type a one-paragraph description of your package. This is probably analogous to the
first paragraph in your package's documentation. (It's optional, so if you're lazy
just skip it for now.)</td>
</tr>

<tr valign=top>
  <th align=right><br>Description:</th>
  <td><textarea name=description cols=60 rows=5 wrap=soft></textarea><br>
This description is <select name=description_format>
<option value=text/html>HTML-formatted.
<option value=text/plain>plain text.
</select>
</td>
</tr>

<tr>
  <td></td>
  <td>Enter the names and URLs of up to two people who own the package.
These should be entered in order of importance: whoever works most heavily
on the package should be first. You'll probably want to use email addresses
for URLs, in which case you should precede them with <tt>mailto:</tt> (e.g.,
<tt>mailto:samoyed@arsdigita.com</tt>).
</tr>

<tr>
  <th align=right nowrap>Primary Owner:</th>
  <td><input name=owner_name.1 size=30 value=\"$user_name\"></td>
</tr>
<tr>
  <th align=right nowrap>Primary Owner URL:</th>
  <td><input name=owner_url.1 size=30 value=\"mailto:$email\" onChange=\"checkMailto(this)\"></td>
</tr>
<tr>
  <th align=right nowrap>Secondary Owner:</th>
  <td><input name=owner_name.2 size=30></td>
</tr>
<tr>
  <th align=right nowrap>Secondary Owner URL:</th>
  <td><input name=owner_url.2 size=30 onChange=\"checkMailto(this)\"></td>
</tr>

<tr>
  <td></td>
  <td>If the package is being released by a company, type in its name and URL here.
ArsDigita employees should <a href=\"javascript:document.forms\[0\].vendor.value='ArsDigita Corporation';document.forms\[0\].vendor_url.value='http://www.arsdigita.com/';void(0)\">click here</a> to fill this in automatically.</td>
</tr>

<tr>
  <th align=right nowrap>Vendor:</th>
  <td><input name=vendor size=30></td>
</tr>
<tr>
  <th align=right nowrap>Vendor URL:</th>
  <td><input name=vendor_url size=60></td>
</tr>

<tr>
  <td></td>
  <td>
    <table><tr valign=baseline><td><input type=checkbox name=install_p value=1 checked></td><td>
Write a package specification file for this package.
(You almost certainly want to leave this checked.)</td></tr></table>
  </td>
</tr>

<tr>
  <td colspan=2 align=center><br>
Congratulations, you have survived the inquisition! Click \"Create Package\" to register
your package.
<p><input type=submit value=\"Create Package\">
</td>
</tr>

</table>

[ad_footer]
"

