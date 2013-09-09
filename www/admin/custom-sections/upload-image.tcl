# /www/admin/custom-sections/upload-image.tcl
ad_page_contract {
    This page lets the user upload animage from the desktop
   
    Scope aware. scope := (public|group). Scope related variables are passed implicitly in 
    the local environment and checked with ad_scope_error_check.

    @author  ahmeds@arsdigita.com
    @creation-date  12/30/99

    @param section_id

    @cvs-id upload-image.tcl,v 3.2.2.8 2001/01/10 17:13:55 khy Exp
} {
    section_id:integer,notnull
}

ad_scope_error_check
ad_scope_authorize $scope admin group_admin none

set section_pretty_name [db_string "cs_select_section_pretty" "
select section_pretty_name 
 from content_sections 
 where section_id = :section_id 
" ]

db_release_unused_handles

# Build the HTML output

set page_title "Upload Image for $section_pretty_name"

set page_body "
[ad_scope_admin_header $page_title]
[ad_scope_admin_page_title $page_title]
[ad_scope_admin_context_bar [list "index.tcl?[export_url_vars section_id]" $section_pretty_name] $page_title]

<hr>
<br>
"

set content_file_id [db_string "cs_select_content_file_id" "
    select content_file_id_sequence.nextval from dual"]

set html "

<h3>Upload an Image for $section_pretty_name Section</h3>

<table cellpadding=4>

<form enctype=multipart/form-data method=post action=\"upload-image-1\">
[export_form_vars section_id]
[export_form_vars -sign content_file_id]

<tr>
<th align=left>Upload File

<td>
<input type=file name=upload_file size=20>
</td>
</tr>

<tr>
<th  align=left>Filename
<td><input type=textarea size=20 name=file_name>
</td>
</tr>

</table>

<p>
<input type=submit value=\"Upload\">
</form>
"

append page_body "
<blockquote>
$html
</blockquote>
[ad_scope_admin_footer ]
"

doc_return  200 text/html $page_body

