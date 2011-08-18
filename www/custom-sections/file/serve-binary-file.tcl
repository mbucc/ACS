# $Id: serve-binary-file.tcl,v 3.0 2000/02/06 03:37:41 ron Exp $
# File:     /custom-sections/serve-binary-file.tcl
# Date:     12/28/99
# Contact:  ahmeds@arsdigita.com
# Purpose:  this serves a custom section image 
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

set_the_usual_form_variables 0
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)
# content_file_id 

ad_scope_error_check

set db [ns_db gethandle]
ad_scope_authorize $db $scope all all none

ReturnHeaders

set page_title "View Image"

ns_write "
[ad_scope_admin_header $page_title $db]
[ad_scope_page_title $page_title $db]
[ad_scope_context_bar_ws "$page_title"]

<hr>
[ad_scope_navbar]
"

set file_name [database_to_tcl_string $db "
select file_name 
from content_files 
where content_file_id = $content_file_id"]

append html "

<center>
<h3>$file_name</h3>
<img src=\"/custom-sections/file/get-binary-file.tcl?[export_url_scope_vars content_file_id]\" ALT=$file_name border=1>
</center>
"

ns_db releasehandle $db

ns_write "
<blockquote>
$html
</blockquote>
[ad_scope_admin_footer]
"

