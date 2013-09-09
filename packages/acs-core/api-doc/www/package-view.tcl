ad_page_contract {
    Shows APIs for a particular package.

    @param version_id the ID of the version whose API to view.
    @param public_p view only public APIs?
    @param kind view which type of APIs? One of <code>procs_files</code>,
        <code>procs</code> or <code>content</code>.
    @author Jon Salz (jsalz@mit.edu)
    @creation-date 3 Jul 2000
    @cvs-id package-view.tcl,v 1.1.4.6 2000/09/07 22:44:51 bquinn Exp
} {
    version_id
    public_p:optional
    { kind "procs_files" }
}

api_set_public $version_id
set public_p [ns_queryget public_p]

db_1row package_name_from_package_id "
    select package_name, package_key, version_name
    from apm_package_version_info
    where version_id = $version_id
"

set title "$package_name $version_name"

set dimensional_list {
    {
	kind "Kind:" procs_files {
	    { procs_files "Library Files" "" }
	    { procs "Procedures" "" }
	    { content "Content Pages" "" }
	}
    }
    {
	public_p "Publicity:" 1 {
	    { 1 "Public Only" }
	    { 0 "All" }
	}
    }
}

doc_body_append "
[ad_header $title]
<h2>$title</h2>
[ad_context_bar_ws_or_index [list "" "API Browser"] $title]
<hr>

<center>
<table><tr>
<td align=right>
[ad_dimensional $dimensional_list]
</td></tr>
</table>
</center>
"

set row_colors { white #EEEEEE }
set counter 0

switch $kind {
    procs_files {
	array set procs [list]

	doc_body_append "<blockquote><table cellspacing=0 cellpadding=0>\n"
	db_foreach file_id_and_path_for_package "
            select file_id, path
	    from apm_package_files
            where version_id = $version_id
            and file_type = 'tcl_procs'
	    order by path
	" {
	    set full_path "packages/$package_key/$path"
	    doc_body_append "
<tr valign=top bgcolor=[lindex $row_colors [expr { $counter % [llength $row_colors] }]]>
  <td><b><a href=\"procs-file-view?version_id=$version_id&path=packages/$package_key/$path\">$path</a></b></td>
  <td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
  <td>"
	    if { [nsv_exists api_library_doc $full_path] } {
		array set doc_elements [nsv_get api_library_doc $full_path]
		doc_body_append "[api_first_sentence [lindex $doc_elements(main) 0]]&nbsp;"
	    }
	    doc_body_append "</td>\n</tr>\n"
	    incr counter
	}
	doc_body_append "</table></blockquote>\n"
    }
    procs {
	array set procs [list]

	doc_body_append "<blockquote><table cellspacing=0 cellpadding=0>\n"

	foreach path [apm_version_file_list -type tcl_procs $version_id] {
	    if { [nsv_exists api_proc_doc_scripts "packages/$package_key/$path"] } {
		foreach proc [nsv_get api_proc_doc_scripts "packages/$package_key/$path"] {
		    set procs($proc) 1
		}
	    }
	}

	foreach proc [lsort [array names procs]] {
	    array set doc_elements [nsv_get api_proc_doc $proc]
	    if { $public_p } {
		if { !$doc_elements(public_p) } {
		    continue
		}
	    }

	    doc_body_append "
<tr valign=top bgcolor=[lindex $row_colors [expr { $counter % [llength $row_colors] }]]>
  <td><b><a href=\"proc-view?version_id=$version_id&proc=$proc\">$proc</a></b></td>
  <td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
  <td>[api_first_sentence [lindex $doc_elements(main) 0]]&nbsp;</td>
</tr>
"
            incr counter
	}
	doc_body_append "</table></blockquote>\n"
    }
    content {
	doc_body_append "<table cellspacing=0 cellpadding=0>\n"
	set last_components [list]
	foreach path [apm_version_file_list -type content_page $version_id] {
	    set components [split $path "/"]
	    if { [info exists doc_elements] } {
		unset doc_elements
	    }
	    # don't stop completely if the page is gone
	    if { [catch {
		array set doc_elements [api_read_script_documentation "packages/$package_key/$path"]
		
		for { set n_same_components 0 } \
			{ $n_same_components < [llength $last_components] } \
			{ incr n_same_components } {
		    if { ![string equal [lindex $last_components $n_same_components] \
			    [lindex $components $n_same_components]] } {
			break
		    }
		}
		for { set i $n_same_components } { $i < [llength $components] } { incr i } {
		    doc_body_append "<tr valign=top bgcolor=[lindex $row_colors [expr { $counter % [llength $row_colors] }]]>\n<td>"
		    for { set j 0 } { $j < $i } { incr j } {
			doc_body_append "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
		    }
		    if { $i == [llength $components] - 1 } {
			doc_body_append "<b><a href=\"content-page-view?version_id=$version_id&path=packages/$package_key/$path\">[lindex $components $i]</a></b>"
			doc_body_append "</td><td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td><td>"
			if { [info exists doc_elements(type)] } {
			    doc_body_append "<a href=\"type-view?type=$doc_elements(type)\">$doc_elements(type)</a>"
			}
			doc_body_append "</td><td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td><td>"
			if { [info exists doc_elements(main)] } {
			    doc_body_append "</td><td>[api_first_sentence [lindex $doc_elements(main) 0]]"
			}
		    } else {
			doc_body_append "<b>[lindex $components $i]/</b>"
		    }
		    doc_body_append "</td></tr>\n"
		}
		set last_components $components
	    } error] } {
		# couldn't read info from the file. it probably doesn't exist.
	    }
	}
	doc_body_append "</table>\n"
    }
    types {
	foreach path [apm_version_file_list -type tcl_procs $version_id] {
	    if { [nsv_exists doc_type_doc_scripts "packages/$package_key/$path"] } {
		foreach type [nsv_get doc_type_doc_scripts "packages/$package_key/$path"] {
		    set types($type) 1
		}
	    }
	}

	foreach type [lsort [array names types]] {
	    doc_body_append "<a href=\"type-view?type=$type\">$type</a><br>\n"
	}
    }
}

doc_body_append [ad_footer]
