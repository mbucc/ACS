# $Id: group-module-remove.tcl,v 3.0 2000/02/06 03:28:57 ron Exp $
# File:     /admin/ug/group-module-remove.tcl
# Date:     01/01/2000
# Contact:  tarik@arsdigita.com
# Purpose:  confirmation page for removing association between module and the group

set_the_usual_form_variables
# group_id, module_key

set db [ns_db gethandle]
set group_name [database_to_tcl_string $db "
select group_name from user_groups where group_id=$group_id"]

set page_title "Remove Module"

ns_return 200 text/html "
[ad_admin_header $page_title]
<h2>$page_title</h2>
[ad_admin_context_bar [list "/admin/ug/" "Group Administration"] \
	[list "group.tcl?group_id=$group_id" "$group_name Administration"] \
	"Confirm Module Removal"]
<hr>
<blockquote>
<h4>Confirm Module Removal</h4>
<table>
<th valign=top>Warning:
<td align=left>Removing module implies that users of $group_name will not be able to use this module.
</table>
<br>Are you sure you want to proceed ?
<form method=post action=\"group-module-remove-2.tcl\">
[export_form_vars group_id module_key]
<input name=confirm_button value=yes type=submit>
[ad_space 5]<input name=confirm_button value=no type=submit>
</form>
</blockquote>
[ad_footer]
"



