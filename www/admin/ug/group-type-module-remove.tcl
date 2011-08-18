# $Id: group-type-module-remove.tcl,v 3.0 2000/02/06 03:29:22 ron Exp $
# File:     /admin/ug/group-type-module-remove.tcl
# Date:     22/12/99
# Contact:  tarik@arsdigita.com
# Purpose:  confirmation page for removing association between module and the group type

set_the_usual_form_variables
# group_type, module_key

set db [ns_db gethandle]
set group_type_pretty_name [database_to_tcl_string $db "
select pretty_name from user_group_types where group_type='$QQgroup_type'"]

set page_title "Remove Module"

ns_return 200 text/html "
[ad_admin_header $page_title]
<h2>$page_title</h2>
[ad_admin_context_bar [list "/admin/ug/" "Group Administration"] \
	[list "group-type.tcl?group_type=[ns_urlencode $group_type]" "$group_type_pretty_name Administration"] \
	"Confirm Module Removal"]
<hr>
<blockquote>
<h4>Confirm Module Removal</h4>
<table>
<th valign=top>Warning:
<td align=left>Removing module implies that user groups of this type will not be able to use this module.
</table>
<br>Are you sure you want to proceed ?
<form method=post action=\"group-type-module-remove-2.tcl\">
[export_form_vars group_type module_key]
<input name=confirm_button value=yes type=submit>
[ad_space 5]<input name=confirm_button value=no type=submit>
</form>
</blockquote>
[ad_footer]
"



