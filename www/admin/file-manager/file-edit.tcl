# /www/admin/file-manager/file-edit.tcl

ad_page_contract {
    @author  ron@arsdigita.com
    @created June 2000
    @cvs-id  file-edit.tcl,v 1.3.2.7 2000/12/20 10:24:45 ron Exp
} {
    {path}
}

# check for image files and redirect to the upload page

if [string match "image/*" [ns_guesstype [file tail $path]]] {
    ad_returnredirect file-upload?path=$path
    return
}

# wrapper for reading a file

proc fm_read_file { path } {

    if { [string index $path 0] != "/" } {
	set dir [file dirname [ns_url2file [ns_conn url]]]
	set path "$dir/$path"
    }
    
    if ![file exists $path] {
	return "No file found at $path"
    }
    
    set text [read [set fd [open $path r]]]
    close $fd
    
    # sub out all the & so that html escapes like "&nbsp;" are not
    # interpreted and sent as normal spaces from the text area 
    regsub -all {&} $text {\&amp;} text

    return $text
}

# Construct the page info for a file

proc fm_file_info { path } {

    set info "
    <table>
    <tr>
    <td><i>File</i></td>
    <td>[file tail $path]</td>
    </tr>
    
    <tr>
    <td><i>Size</i></td>
    <td>[file size $path] bytes</td>
    </tr>
    
    <tr>
    <td><i>Last modified</i></td>
    <td>[ns_fmttime [file mtime $path]]</td>
    </tr>
    "

    # If we're using version control, go ahead and grab the summary
    # information  

    if [ad_parameter VersionControlP file-manager 0] {
	set revision [vc_fetch_revision $path]

	if ![empty_string_p $revision] {
	    append info "
    <tr>
    <td><i>Revision</i></td>
    <td>$revision</td>
    </tr>
    "
	}
    }

    return [concat $info "\n</table>\n"]
}

# Guess the appropriate textarea size for a file

proc fm_guess_size { content } {

    set rows_max 40

    set rows [llength [split $content "\n"]]
    if {$rows > $rows_max} {
	set rows $rows_max
    }

    return "rows=$rows cols=80"
}

set file_content [fm_read_file $path]

doc_return  200 text/html "
[ad_admin_header "File Manager"]

<h2>File Manager</h2>

[fm_admin_context_bar]

<hr>

[help_upper_right_menu \
	[list "file-upload?path=$path" "Upload"] \
	[list "[fm_pageroot_relative_path $path]" "View"]]

<h3>Edit contents of [fm_linked_path $path]</h3>

<p>

<form method=post action=file-edit-2>

<input type=hidden name=path value=\"$path\">

[fm_file_info $path]

<table>
<tr>
<td>
<textarea name=file_content [fm_guess_size $file_content] nowrap>$file_content</textarea>
</td>
</tr>

<tr>
<td colspan=2><br><b>Describe changes:</b></td>
</tr>

<tr>
<td colspan=2><input type=text size=80 name=message></td>
</tr>

<tr>
<td colspan=2><input type=submit value=Commit></td>
</tr>

</table>
</form>

[ad_admin_footer]
"


