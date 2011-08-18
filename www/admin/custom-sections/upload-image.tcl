# $Id: upload-image.tcl,v 3.0 2000/02/06 03:16:18 ron Exp $
# File:     admin/custom-sections/upload-image.tcl
# Date:     12/30/99
# Contact:  ahmeds@arsdigita.com
# Purpose:  This page lets the user upload animage from the desktop
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

ReturnHeaders

set_the_usual_form_variables 0
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)
# section_id

ad_scope_error_check

set db [ns_db gethandle]

ad_scope_authorize $db $scope admin group_admin none


set exception_count 0
set exception_text ""

set section_pretty_name [database_to_tcl_string $db "
select section_pretty_name
from content_sections
where section_id=$section_id
"]

set page_title "Upload Image for $section_pretty_name"

ns_write "
[ad_scope_admin_header $page_title $db]
[ad_scope_admin_page_title $page_title $db]
[ad_scope_admin_context_bar [list "index.tcl?[export_url_scope_vars section_id]" $section_pretty_name] $page_title]

<hr>
<br>
"

set content_file_id [database_to_tcl_string $db "
    select content_file_id_sequence.nextval from dual"]

set html "

<h3>Upload an Image for $section_pretty_name Section</h3>

<table cellpadding=4>

<form enctype=multipart/form-data method=post action=\"upload-image-1.tcl\">
[export_form_scope_vars section_id content_file_id]

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

ns_db releasehandle $db

ns_write "
<blockquote>
$html
</blockquote>
[ad_scope_admin_footer ]
"

