# /www/admin/file-manager/file-list.tcl

ad_page_contract {
    @author  karlg@arsdigita.com
    @author  ron@arsdigita.com
    @created June 2000
    @cvs-id  file-list.tcl,v 1.3.2.4 2000/09/22 01:35:09 kevin Exp
} {
    {path ""}
}

set output "
[ad_admin_header "File Manager"]

<h2> File Manager </h2>

[fm_admin_context_bar]

<hr>
"

if [empty_string_p $path] {

    append output "<p>Choose a directory to list its contents.</p>"

} else {

    append output "

    [help_upper_right_menu \
	    [list "file-upload?path=$path" "Add a File"] \
	    [list "file-mkdir?path=$path" "Add a Directory"]]

    <h3>Files in [fm_linked_path $path]</h3>\n"

    set ignore     [split [ad_parameter Ignore     file-manager "admin"] ","]
    set extensions [split [ad_parameter Extensions file-manager "html"] ","]

    if [catch {

	set files [glob $path/*]

	set output_dirs ""
	set output_files ""

	foreach file [lsort $files] {

	    set tail [file tail $file]

	    if {[lsearch $ignore $tail] != -1} {
		continue
	    }

	    if [file isdirectory $file] { 
		append output_dirs "
		<tr>
		<td align=left valign=top>
		<img border=0 src=/graphics/file-manager/folder.gif>
		</td>
		<td align=left valign=top>
		<a href=file-list?path=$file target=list>$tail</a>
		</td>
		</tr>
		"
	    } else {

		if {[lsearch $extensions [string trimleft [file extension $file] "."]] != -1} {

		    # Determine if this file is locked or editable
		    set locked_p 0
		    if [ad_parameter VersionControlP file-manager 0] {
			if ![regexp -nocase "status: up-to-date" [vc_fetch_status $file]] {
			    set locked_p 1
			}
		    }
		    
		    switch -glob [ns_guesstype $tail] {
			image/* {
			    if {$locked_p} {
				append output_files "
				<tr>
				<td align=left valign=top>
				<a href=[fm_pageroot_relative_path $file]><img border=0 src=/graphics/file-manager/locked.gif></a>
				</td>
				<td align=left valign=top>
				<i>$tail</i>
				</td>
				</tr>
				"
			    } else {
				append output_files "
				<tr>
				<td align=left valign=top>
				<a href=[fm_pageroot_relative_path $file]><img border=0 src=/graphics/file-manager/image.gif></a>
				</td>
				<td align=left valign=top>
				<a href=file-upload?path=$file target=list>$tail</a>
				</td>
				</tr>
				"
			    }
			}

			text/* {
			    if {$locked_p} {
				append output_files "
				<tr>
				<td align=left valign=top>
				<a href=[fm_pageroot_relative_path $file]><img border=0 src=/graphics/file-manager/locked.gif></a>
				</td>
				<td align=left valign=top>
				<i>$tail</i>
				</td>
				</tr>
				"
			    } else {
				append output_files "
				<tr>
				<td align=left valign=top>
				<a href=[fm_pageroot_relative_path $file]><img border=0 src=/graphics/file-manager/text.gif></a>
				</td>
				<td align=left valign=top>
				<a href=file-edit?path=$file target=list>$tail</a>
				</td>
				</tr>
				"
			    }
			}

			default {
			    append output_files "
			    <tr>
			    <td align=left valign=top>
			    <img border=0 src=/graphics/file-manager/unknown.gif>
			    </td>
			    <td align=left valign=top>
			    <i>$tail</i>
			    </td>
			    </tr>
			    "
			}
		    }

		} else {
		    append output_files "
		    <tr>
		    <td align=left valign=top>
		    <img border=0 src=/graphics/file-manager/forbidden.gif>
		    </td>
		    <td align=left valign=top>
		    <i>$tail</i>
		    </td>
		    </tr>
		    "
		}
	    }
	}

	append output "
	<blockquote>
	<table border=0 cellpadding=0 cellspacing=0>	
	$output_dirs
	$output_files
	</table>
	</blockquote>\n"
    } errmsg] {
	append output "<p>No editable files found</p>"
    }
}

append output "[ad_admin_footer]"

doc_return  200 text/html $output

