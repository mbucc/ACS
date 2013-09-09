# /www/admin/file-manager/file-upload.tcl

ad_page_contract { 

    Upload a new file or replace existing file contents

    @author  ron@arsdigita.com
    @created Fri May 26 06:12:27 2000
    @cvs-id  file-upload.tcl,v 1.3.2.3 2000/09/22 01:35:12 kevin Exp
} {
    {path:trim}
}

set page_content "
[ad_admin_header "File Manager"]

<h2>File Manager</h2>

[fm_admin_context_bar]

<hr>

[help_upper_right_menu \
	[list "file-edit?path=$path" "Edit"] \
	[list "[fm_pageroot_relative_path $path]" "View"]]
"

# If the given path is a directory, we're adding a new file.
# Otherwise we're replacing the content of an existing file.

if [file isdirectory $path] {
    append page_content "
    <h3> Add file to [fm_linked_path $path] </h3>

    <p> Use the form below to add a new file.  Specify the title the
    file will have on the web server and click <i>Browse</i> to select
    the existing file on your local computer.</p>

    <form enctype=multipart/form-data method=post action=file-upload-2>
    [export_form_vars path]
    <table>

    <tr>
    <th align=right>Title:</th>
    <td><input type=text name=title size=20></td>
    </tr>

    <tr>
    <th align=right>File name:</rh>
    <td><input type=file name=the_file></td>
    </tr>

    <tr>
    <th>Describe changes:</th>
    <td><input type=text size=60 name=message></td>
    </tr>

    <tr>
    <td></td>
    <td><input type=submit value=Upload></td>
    </tr>
    </table>\n"
} else {
    append page_content "
    <h3> Upload new version of [fm_linked_path $path] </h3>

    <p> Use the form below to upload new content.  Choose an existing
    file on your local computer by clicking the <i>Browse</i>
    button.</p>
 
    <form enctype=multipart/form-data method=post action=file-upload-2>
    [export_form_vars path]
    <table>

    <tr>
    <th align=right>File name:</rh>
    <td><input type=file name=the_file></td>
    </tr>

    <tr>
    <th>Describe changes:</th>
    <td><input type=text size=60 name=message></td>
    </tr>

    <tr>
    <td></td>
    <td><input type=submit value=Upload></td>
    </tr>
    </table>\n"
}

append page_content "[ad_admin_footer]"

doc_return  200 text/html $page_content

