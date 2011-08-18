# $Id: add-page.tcl,v 3.0 2000/02/06 03:16:03 ron Exp $
# File:     admin/custom-sections/add-page.tcl
# Date:     12/30/99
# Contact:  ahmeds@arsdigita.com
# Purpose:  adds custom section page
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

set page_title "Add Page"
set section_pretty_name [database_to_tcl_string $db "
    select section_pretty_name 
    from content_sections 
    where section_id = $section_id"]

set content_file_id [database_to_tcl_string $db "select content_file_id_sequence.nextval from dual"]

ns_write "
[ad_scope_admin_header $page_title $db]
[ad_scope_admin_page_title $page_title $db]
[ad_scope_admin_context_bar [list "index.tcl?[export_url_scope_vars section_id]" $section_pretty_name] $page_title]

<hr>
<br>

<blockquote>
<h3>Add Page</h3>
<br>

<form method=post action=\"add-page-2.tcl\">

[export_form_scope_vars section_id content_file_id]

<b>File Name</b>
[ad_space 8]
<input type=text name=file_name size=20>
<br><br><br>

<b>Page Pretty Name</b>
[ad_space 8]
<input type=text name=page_pretty_name size=20>
<br><br><br>


<b>Page Content</b>
<br>
<textarea name=body cols=60 rows=16 wrap=soft></textarea>
<br><br><br>

Text above is
<select name=html_p>
<option value=f selected>Plain Text
<option value=t>HTML
</select>

<center>
<input type=submit value=\"Add\">
</center>

</form>
</blockquote>

[ad_scope_admin_footer]
"

