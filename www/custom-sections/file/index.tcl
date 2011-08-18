# $Id: index.tcl,v 3.0 2000/02/06 03:37:40 ron Exp $
# File:     /custom-sections/index.tcl
# Date:     12/28/99
# Contact:  ahmeds@arsdigita.com
# Purpose:  this serves the custom section index page 
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

set selection [ns_db 1row $db "
select page_pretty_name, body, html_p
from content_files
where content_file_id=$content_file_id
"]

set_variables_after_query

ReturnHeaders

append html "
[ad_scope_header $page_pretty_name $db]
[ad_scope_page_title $page_pretty_name $db]
[ad_scope_context_bar_ws "$page_pretty_name"]
<hr>
[ad_scope_navbar]
"   
append html "
<br><br>
<blockquote>
<h2>$page_pretty_name</h2>
[util_maybe_convert_to_html $body $html_p]
</blockquote>
<p>
"

ns_write "
$html
[ad_scope_footer ]
"

