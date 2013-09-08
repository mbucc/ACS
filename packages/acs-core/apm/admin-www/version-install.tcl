ad_page_contract { 
    Installs or upgrades to a new version of a package.
    @author Jon Salz [jsalz@arsdigita.com]
    @date 9 May 2000
    @cvs-id version-install.tcl,v 1.5.2.3 2000/07/21 03:55:47 ron Exp
} {
    {version_id:integer}
}

db_1row apm_package_by_version_id {
    select package_name, version_name from apm_package_version_info where version_id = :version_id
}
doc_body_append "[apm_header -form "action=version-install-2.tcl" "Install $package_name $version_name"]

[export_form_vars version_id]

Do you want to load this package directly into the filesystem, or import it into
CVS? Loading it directly into the filesystem is simpler and immediate, but
importing it into CVS allows you to make local modifications to the code, maintaining
them even when you later upgrade this package.

<blockquote><b>Note:</b> CVS imports are experimental and unsupported in ACS 3.3.</blockquote>

<p><center>
<table cellpadding=0 cellspacing=0>

<tr valign=baseline>
<td><input type=radio name=cvs_p value=1>&nbsp;</td>
<td>Import this package into CVS.</td>
</tr>

<tr valign=baseline>
<td><input type=radio name=cvs_p value=0 checked>&nbsp;</td>
<td>Load the package directly.</td>
</tr>

</table>

<p>
<input type=button value=\"Cancel\" onClick=\"location.href='version-view.tcl?version_id=$version_id'\">
<spacer type=horizontal size=50>
<input type=submit value=\"OK\">

</center>

[ad_footer]
"

