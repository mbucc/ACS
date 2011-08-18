# $Id: remove-module.tcl,v 3.0 2000/02/06 03:15:18 ron Exp $
# File:     /admin/content-sections/module-remove.tcl
# Date:     01/01/2000
# Contact:  tarik@arsdigita.com
# Purpose:  confirmation page for removing association between module and the group

set_the_usual_form_variables
# scope, group_id, section_key

ad_scope_error_check
set db [ns_db gethandle]
ad_scope_authorize $db $scope none group_admin none

set group_name [ns_set get $group_vars_set group_name]

set page_title "Remove Module"

ns_return 200 text/html "
[ad_scope_admin_header $page_title $db]
[ad_scope_admin_page_title $page_title $db]
[ad_scope_admin_context_bar [list "index.tcl?[export_url_scope_vars]" "Content Sections"] $page_title]
<hr>
<blockquote>
<h4>Confirm Module Removal</h4>
<table>
<th valign=top>Warning:
<td align=left>Removing module implies that users of $group_name will not be able to use this module.
</table>
<br>Are you sure you want to proceed ?
<form method=post action=\"remove-module-2.tcl\">
[export_form_scope_vars section_key]
<input name=confirm_button value=yes type=submit>
[ad_space 5]<input name=confirm_button value=no type=submit>
</form>
</blockquote>
[ad_scope_footer]
"
