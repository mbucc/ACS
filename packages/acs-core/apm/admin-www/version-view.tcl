ad_page_contract {
    Views information about a package.
    @author Jon Salz [jsalz@arsdigita.com]
    @date 17 April 2000
    @cvs-id version-view.tcl,v 1.8.2.3 2000/07/21 03:55:48 ron Exp
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
db_1row apm_file_count {
	select count(*) n_files from apm_package_files where version_id = :version_id
}

set downloaded_p [ad_decode $distribution_url "" 0 1]

# Obtain information about the enabled version of the package (if there is one).
db_0or1row apm_enabled_version_info {
    select version_id as installed_version_id, version_name as installed_version_name,
           enabled_p as installed_enabled_p,
           apm_version_compare(version_name, :version_name) as installed_version_compare
    from   apm_package_versions
    where  package_id = :package_id
    and    installed_p = 't'
}

db_0or1row apm_data_model_install_version {
    select data_model_installed_version from (
        select version_name as data_model_installed_version
        from   apm_package_versions
        where  package_id = :package_id
        and    data_model_loaded_p = 't'
        order by apm_version_order(version_name) desc
    )
    where rownum = 1
}

if { [empty_string_p $vendor] } {
    set vendor $vendor_url
}
foreach field { summary description release_date vendor package_group } {
    if { [empty_string_p [set $field]] } {
	set $field "-"
    }
}

# Later we'll output any items in "prompts" as entries in a bullet list at the
# top of the page (these are things that the administrator probably needs to
# address ASAP).
set prompts [list]

if { ![info exists installed_version_id] } {
    if { !$downloaded_p } {
	set status "No version of this package is installed: there is no <tt>.info</tt> file in the
<tt>packages/$package_key</tt> directory. If you're building the package now, you probably
want to <a href=\"version-generate-info.tcl?version_id=$version_id&write_p=1\">generate one</a>."
    } else {
	set status "No version of this package is installed. You may <a href=\"version-install.tcl\?version_id=$version_id\">install this package now</a>."
    }
    lappend prompts $status
} elseif { $installed_version_id == $version_id } {
    set status "This version of the package is installed"
    if { $enabled_p == "t" } {
	append status " and enabled."
	set can_disable_p 1
    } else {
	append status " but disabled."
	set can_enable_p 1
    }
} else {
    set status "[ad_decode $installed_version_compare -1 "An older" "A newer"] version of this package,
version $installed_version_name, is installed and [ad_decode $installed_enabled_p "t" "enabled" "disabled"]."
    if { $installed_version_compare < 0 } {
	doc_body_append " You may <a href=\"version-install?version_id=$version_id\">upgrade to this version now</a>."
    }
}

if { ![info exists data_model_installed_version] } {
    set data_model_status " No version of the data model for this package has been loaded."
} elseif { [string compare $data_model_installed_version $version_name] } {
    set data_model_status " The data model for version $data_model_installed_version of this package has been
loaded."
} else {
    set data_model_status " The data model for this version of this package has been loaded."
}

if { $imported_p == "t" } {
    set cvs_status "This package has been imported into CVS (release tag [apm_package_version_release_tag $package_key $version_name])."
} else {
    if { [file isdirectory "[acs_package_root_dir $package_key]/CVS"] } {
	set cvs_status "This package is under local CVS control."
    } else {
	set cvs_status "This package is not under CVS control."
    }
}

if { $n_files < 2 && [empty_string_p $distribution_url] } {
    lappend prompts "There [ad_decode $n_files 0 "are no files" "is only one file"] registered for this package. You probably want to
<a href=\"file-add.tcl?version_id=$version_id\">scan the usual places in the filesystem for files in this package</a>."
}

# Obtain a list of owners, properly hyperlinked.
set owners [list]
db_foreach apm_all_owners {
    select owner_url, owner_name from apm_package_owners where version_id = :version_id
} {
    if { [empty_string_p $owner_url] } {
	lappend owners $owner_name
    } else {
	lappend owners "$owner_name (<a href=\"$owner_url\">$owner_url</a>)"
    }
}

if { [llength $owners] == 0 } {
    lappend owners "-"
}

if { [llength $prompts] == 0 } {
    set prompt_text ""
} else {
    set prompt_text "<ul><li>[join $prompts "\n<li>"]</ul>"
}

db_release_unused_handles
doc_body_append "[apm_header "$package_name $version_name"]

$prompt_text

<h3>Package Information</h3>

<blockquote>
<table>
<tr valign=baseline><th align=left>Package Name:</th><td>$package_name</td></th></tr>
<tr valign=baseline><th align=left>Version:</th><td>$version_name</td></tr>
<tr valign=baseline><th align=left>Status:</th><td>$status</td></tr>
<tr valign=baseline><th align=left>Data Model:</th><td>$data_model_status</td></th></tr>
<tr valign=baseline><th align=left>CVS:</th><td>$cvs_status</td></tr>
<tr valign=baseline><th align=left>[ad_decode [llength $owners] 1 "Owner" "Owners"]:</th><td>[join $owners "<br>"]</td></th></tr>
<tr valign=baseline><th align=left>Registered Files:</th><td>$n_files</td></th></tr>
<tr valign=baseline><th align=left>Package Key:</th><td>$package_key</td></th></tr>
<tr valign=baseline><th align=left>Summary:</th><td>$summary</td></tr>
<tr valign=baseline><th align=left>Description:</th><td>$description</td></tr>
<tr valign=baseline><th align=left>Release Date:</th><td>$release_date</td></tr>
<tr valign=baseline><th align=left>Vendor:</th><td>[ad_decode $vendor_url "" $vendor "<a href=\"$vendor_url\">$vendor</a>"]</td></tr>
<tr valign=baseline><th align=left>Group:</th><td>$package_group</td></tr>
<tr valign=baseline><th align=left>Package URL:</th><td><a href=\"$package_url\">$package_url</a></td></th></tr>
<tr valign=baseline><th align=left>Version URL:</th><td><a href=\"$version_url\">$version_url</a></td></th></tr>
<tr valign=baseline><th align=left>Distribution File:</th><td>"

if { ![empty_string_p $tarball_length] && $tarball_length > 0 } {
    doc_body_append "<a href=\"packages/[file tail $version_url]?version_id=$version_id\">[format "%.1f" [expr { $tarball_length / 1024.0 }]]KB</a> "
    if { [empty_string_p $distribution_url] } {
	doc_body_append "(generated on this system"
	if { ![empty_string_p $distribution_date] } {
	    doc_body_append " on $distribution_date"
	}
	doc_body_append ")"
    } else {
	doc_body_append "(downloaded from $distribution_url"
	if { ![empty_string_p $distribution_date] } {
	    doc_body_append " on $distribution_date"
	}
	doc_body_append ")"
    }
} else {
    doc_body_append "None available"
    if { $installed_p == "t" } {
	doc_body_append " (<a href=\"version-generate-tarball.tcl?version_id=$version_id\">generate one now</a> from the filesystem)"
    }
}

doc_body_append "
</td></tr>
<tr valign=baseline><th align=left nowrap>Included Packages:</th><td>"

db_foreach apm_version_url {
    select i.version_url included_version_url, v.version_id included_version_id, v.installed_p included_installed_p
    from   apm_package_includes i, apm_package_versions v
    where  i.version_id = :version_id
    and    i.version_url = v.version_url(+)
    order by i.version_url
} {
    doc_body_append "$included_version_url<br>\n"
} else {
    doc_body_append "-"
}

doc_body_append "
</td></tr>
</table>
"

doc_body_append "
</blockquote>

<ul>
<li><a href=\"version-edit.tcl?version_id=$version_id\">Edit information for this version of the package</a>
<li><a href=\"version-dependencies.tcl?version_id=$version_id\">Manage dependency information</a>
<li><a href=\"version-files.tcl?version_id=$version_id\">Manage file information</a>
<!--<li><a href=\"version-parameters?version_id=$version_id\">Manage parameter information</a>-->
</ul>

<h3>Manage This Package</h3>
<ul>

"

doc_body_append "
<li><a href=\"version-generate-info.tcl?version_id=$version_id\">Display an XML package specification file for this version</a>
"

if { ![info exists installed_version_id] || $installed_version_id == $version_id && \
	[empty_string_p $distribution_url] } {
    # As long as there isn't a different installed version, and this package is being
    # generated locally, allow the user to write a specification file for this version
    # of the package.
    doc_body_append "<li><a href=\"version-generate-info.tcl?version_id=$version_id&write_p=1\">Write an XML package specification to the <tt>packages/$package_key/$package_key.info</tt> file</a>\n"
}

if { $installed_p == "t" } {
    if { [empty_string_p $distribution_url] } {
	# The distribution tarball was either (a) never generated, or (b) generated on this
	# system. Allow the user to make a tarball based on files in the filesystem.
	doc_body_append "<li><a href=\"version-generate-tarball.tcl?version_id=$version_id\">Generate a distribution file for this package from the filesystem</a>\n"
    }

#    if { ![empty_string_p $tarball_length] && $tarball_length > 0 } {
#	# We have a distribution tarball; allow the user to see what's changed.
#	doc_body_append "<li><a href=\"version-generate-diffs.tcl?version_id=$version_id\">Show local modifications made to this package</a>\n"
#    }
}

if { [info exists can_disable_p] } {
    doc_body_append "<p><li><a href=\"version-disable.tcl?version_id=$version_id\">Disable this version of the package</a>\n"
}
if { [info exists can_enable_p] } {
    doc_body_append "<p><li><a href=\"version-enable.tcl?version_id=$version_id\">Enable this version of the package</a>\n"
}

doc_body_append "<p>"

if { $installed_p == "t" } {
    doc_body_append "<li><a href=\"javascript:if(confirm('Are you sure you want to deinstall this package?\\nThis will remove the $package_key directory from the ACS tree.'))location.href='version-deinstall.tcl?version_id=$version_id'\">Deinstall this package</a>\n"
}

doc_body_append "
<li><a href=\"javascript:if(confirm('Are you sure you want to delete this version of this package?'))location.href='version-delete.tcl?version_id=$version_id'\">Delete this version of the package</a> (be very careful!)
</ul>

[ad_footer]
"

