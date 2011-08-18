# $Id: index.tcl,v 3.0 2000/02/06 03:16:31 ron Exp $
# File:     /display/index.tcl
# Date:     12/27/99
# Contact:  tarik@arsdigita.com
# Purpose:  display settings administration page
#
# Note:     if this page is accessed through /groups/admin pages then
#           group_id, group_name, short_name and admin_email are already
#           set up in the environment by the ug_serve_section

set_the_usual_form_variables 0
# maybe return_url
# maybe scope, maybe scope related variables (group_id, user_id)


ad_scope_error_check

set db [ns_db gethandle]

append html "

<a href=\"edit-simple-css.tcl?[export_url_scope_vars return_url]\">
Cascaded Style Sheet Settings</a><br>

<a href=\"upload-logo.tcl?[export_url_scope_vars return_url]\">
Logo Settings</a>
"

set page_title "Display Settings"

ns_return 200 text/html "
[ad_scope_admin_header $page_title $db]
[ad_scope_admin_page_title $page_title $db]
[ad_scope_admin_context_bar "Display Settings"]

<hr>
<blockquote>
$html
</blockquote>
[ad_scope_admin_footer]
"

