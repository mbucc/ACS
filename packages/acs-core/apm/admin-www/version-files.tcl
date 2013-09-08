ad_page_contract { 
    List all the files in a particular version of a package.

    @param version_id The package to be processed.
    @param remove_files_p Set to 1 if you want to remove all the files. 
    @author Jon Salz [jsalz@arsdigita.com]
    @date 9 May 2000
    @cvs-id version-files.tcl,v 1.6.2.4 2000/07/21 03:55:46 ron Exp
} {
    {version_id:integer}
    {remove_files_p 0}
}

db_1row apm_package_by_version_id {
	select package_name, version_name, package_id, package_key, installed_p, distribution_url,
	tagged_p
	from apm_package_version_info where version_id = :version_id
}

if { $remove_files_p == 1 } {
    # This is really a "remove multiple files" page.
    set form "action=\"file-remove.tcl\" method=post"
    set apm_header_args [list [list "version-files.tcl?version_id=$version_id" "Files"] "Remove Files"]
} else {
    set form ""
    set apm_header_args [list "Files"]
}

doc_body_append "[eval [concat [list apm_header -form $form [list "version-view.tcl?version_id=$version_id" "$package_name $version_name"]] $apm_header_args]]
"

doc_body_append "

<blockquote>
<table cellspacing=0 cellpadding=0>
"
doc_body_flush

set last_components [list]
set counter 0
db_foreach apm_all_files {
    select f.file_id, f.path, f.file_type, nvl(t.pretty_name, 'Unknown type') pretty_name
    from   apm_package_files f, apm_package_file_types t
    where  f.version_id = :version_id
    and    f.file_type = t.file_type_key(+)
    order by path
} {
    incr counter

    # Set i to the index of the last component which hasn't changed since the last component
    # we wrote out.
    set components [split $path "/"]
    for { set i 0 } { $i < [llength $components] - 1 && $i < [llength $last_components] - 1 } { incr i } {
	if { [string compare [lindex $components $i] [lindex $last_components $i]] } {
	    break
	}
    }

    # For every changed component (at least the file name), write a row in the table.
    while { $i < [llength $components] } {
	doc_body_append "<tr><td>"
	for { set j 0 } { $j < $i } { incr j } {
	    doc_body_append "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
	}
	if { $installed_p == "f" || [file exists "[acs_package_root_dir $package_key]/$path"] } {
	    # Either we're not looking at an installed package, or the file still exists,
	    # so don't use <strike> when writing the name.
	    doc_body_append [lindex $components $i]
	} else {
	    # This is an installed package, and a file has been removed from the filesystem.
	    # Use <strike> to indicate that the file has been deleted.
	    doc_body_append "<strike>[lindex $components $i]</strike>"
	    if { $i == [llength $components] - 1 } {
		lappend stricken_files $file_id
	    }
	}
	if { $i < [llength $components] - 1 } {
	    doc_body_append "/</td>"
	} else {
	    doc_body_append "</td>"
	    doc_body_append "<td width=40>&nbsp;</td><td>$pretty_name</td><td width=40>&nbsp;</td>"
	    if { $remove_files_p == 1 } {
		# Display a checkbox which the user can check to delete the file.
		doc_body_append "<td><input type=checkbox name=file_id value=$file_id></td>"
	    } else {
		if { $installed_p == "t" } {
		    if { $file_type == "tcl_procs" } {
			if { [nsv_exists apm_reload_watch "packages/$package_key/$path"] } {
			    # This procs file is already being watched.
			    doc_body_append "<td>&nbsp;watch&nbsp;</td>"
			} else {
			    # Provide a link to watch the procs file.
			    doc_body_append "<td>&nbsp;<a href=\"file-watch.tcl?file_id=$file_id\">watch</a>&nbsp;</td>"
			}
		    } else {
			doc_body_append "<td></td>"
		    }
		}
		# Allow the user to remove the file from the package.
		doc_body_append "<td><a href=\"javascript:if(confirm('Are you sure you want to remove this file from the package?\\nDoing so will not remove it from the filesystem.'))location.href='file-remove.tcl?file_id=$file_id'\">remove</a></td>"
	    }		
	}
	doc_body_append "</tr>\n"
	incr i
    }
    set last_components $components
} else {
    doc_body_append "<tr><td>This package does not contain any registered files.</td></tr>\n"
}

if { $counter > 0 && $remove_files_p == 1 } {
    doc_body_append "<tr><td colspan=3></td><td colspan=2><input type=button value=\"Remove Checked Files\" onClick=\"javascript:if(confirm('Are you sure you want to remove these files from the package?\\nDoing so will not remove them from the filesystem.'))form.submit()\"></td>"
}

doc_body_append "
</table>
</blockquote>
"

if { $remove_files_p } {
    doc_body_append "<ul><li><a href=\"version-files.tcl?version_id=$version_id\">Cancel the removal of files</a></ul>\n"
} else {
    if { $installed_p == "t" } {
	doc_body_append "<ul>
<li><a href=\"file-add.tcl?version_id=$version_id\">Scan the <tt>packages/$package_key</tt> directory for additional files in this package</a>
<li><a href=\"version-files.tcl?version_id=$version_id&remove_files_p=1\">Remove several files from this package</a>
"

        if { [info exists stricken_files] } {
	    foreach file_id $stricken_files {
		lappend stricken_file_query "file_id=$file_id"
	    }
	    doc_body_append "<li><a href=\"file-remove.tcl?[join $stricken_file_query "&"]\">Remove nonexistent (crossed-out) files</a>\n"
	}

        if { [empty_string_p $distribution_url] } {
	    doc_body_append "
	<p>
	<!--li><a href=\"version-tag.tcl?version_id=$version_id\">Create a CVS tag for this version in each file</a-->
"
        }

	if {$tagged_p == "t"} {
	    doc_body_append "
	    <li><a href=\"archive/[file tail $version_url]?version_id=$version_id\">Download a tarball from the package archive</a>"
	}

	doc_body_append "</ul>"

    } elseif { [info exists tagged_p] } {
	if { $tagged_p == "t" } {
	    doc_body_append "<ul>
	    <li><a href=\"archive/[file tail $version_url]?version_id=$version_id\">Download a tarball from the package archive</a>
	    </ul>
	    "
	}
    }
}

doc_body_append [ad_footer]

