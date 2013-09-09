ad_page_contract {
    Allows the user to add files to a package.
    @param version_id The identifier for the package.
    @author Jon Salz [jsalz@arsdigita.com]
    @date 17 April 2000
    @cvs-id file-add.tcl,v 1.4.2.8 2000/07/21 03:55:42 ron Exp
} {
    {version_id:integer}
}

db_1row apm_package_by_version_id {
    select package_name, version_name, package_id, package_key, installed_p, distribution_url, tagged_p
    from apm_package_version_info where version_id = :version_id
}

doc_body_append "[apm_header -form "method=post action=\"file-add-2.tcl\"" [list "version-view.tcl?version_id=$version_id" "$package_name $version_name"] [list "version-files.tcl?version_id=$version_id" "Files"] "Add Files"]

[export_form_vars version_id]

<blockquote>
<table cellspacing=0 cellpadding=0>
"

doc_body_flush

# Obtain a list of all files registered to the package already.
array set registered_files [list]
foreach file [db_list apm_file_paths {
    select path from apm_package_files where version_id = :version_id
}] {
    set registered_files($file) 1
}

db_release_unused_handles

# processed_files is a list of sublists, each of which contains
# the path of a file and its file type.
set processed_files [list]
set counter 0

foreach file [lsort [ad_find_all_files [acs_package_root_dir $package_key]]] {
    set relative_path [ad_make_relative_path $file]

    # Now kill "packages" and the package_key from the path.
    set components [split $relative_path "/"]
    set relative_path [join [lrange $components 2 [llength $components]] "/"]

    if { [info exists registered_files($relative_path)] } {
	doc_body_append "<tr><td></td><td>$relative_path (already registered to this package)</td></tr>\n"
    } else {
	set type [apm_guess_file_type $relative_path]
	doc_body_append "<tr><td><input type=checkbox name=file_index value=[llength $processed_files] checked>&nbsp;</td><td><b>$relative_path</b>: [apm_pretty_name_for_file_type $type]</td></tr>\n"
	lappend processed_files [list $relative_path $type]
    }
    incr counter
}

# Since there may be a whole lot of files here, we'll store them in a client property
# (that's the easiest way to get them from this page to the next).
ad_set_client_property apm file_list $processed_files

if { $counter == 0 } {
    doc_body_append "<tr><td colspan=2>There are no files in the <tt>packages/$package_key</tt> directory.</td></tr></table></blockquote>"
} elseif { [llength $processed_files] > 0 } {
    doc_body_append "</table></blockquote>
<script language=javascript>
function uncheckAll() {
    for (var i = 0; i < [llength $processed_files]; ++i)
        document.forms\[0\].file_index\[i\].checked = false;
}
function checkAll() {
    for (var i = 0; i < [llength $processed_files]; ++i)
        document.forms\[0\].file_index\[i\].checked = true;
}
</script>
<blockquote>
\[ <a href=\"javascript:checkAll()\">check all</a> |
<a href=\"javascript:uncheckAll()\">uncheck all</a> \]
</blockquote>

<center>
<input type=submit value=\"Add Checked Files\">
"
} else {
    doc_body_append "<tr><td colspan=2><br>There are no additional files to add to the package.</td></tr></table></blockquote>"
}

doc_body_append "</center>\n[ad_footer]\n"

