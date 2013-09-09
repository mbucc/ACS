# File:     /admin/ug/group-module-remove.tcl

ad_page_contract {
    Purpose:  confirmation page for removing association between module and the group
    @param group_id the ID of the group
    @param module_key the handle for the module

    @cvs-id group-module-remove.tcl,v 3.2.2.5 2000/09/22 01:36:13 kevin Exp
    @author tarik@arsdigita.com
    @creation-date 1 January 2000
} {
    group_id:notnull,naturalnum
    module_key:notnull
}


set group_name [db_string get_group_name "
select group_name from user_groups where group_id=:group_id"]

set page_title "Remove Module"

set page_html "
[ad_admin_header $page_title]
<h2>$page_title</h2>
[ad_admin_context_bar [list "/admin/ug/" "Group Administration"] \
	[list "group?group_id=$group_id" "$group_name Administration"] \
	"Confirm Module Removal"]
<hr>
<blockquote>
<h4>Confirm Module Removal</h4>
<table>
<th valign=top>Warning:
<td align=left>Removing module implies that users of $group_name will not be able to use this module.
</table>
<br>Are you sure you want to proceed ?
<form method=post action=\"group-module-remove-2\">
[export_form_vars group_id module_key]
<input name=confirm_button value=yes type=submit>
[ad_space 5]<input name=confirm_button value=no type=submit>
</form>
</blockquote>
[ad_footer]
"

doc_return  200 text/html $page_html