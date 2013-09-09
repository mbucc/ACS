#/admin/ug/group-type-module-remove.tcl

ad_page_contract { 
    confirmation page for removing association between module and the group type
    @param group_type the type of group
    @param module_key the module handle

    @cvs-id group-type-module-remove.tcl,v 3.2.2.5 2000/09/22 01:36:15 kevin Exp
    @author tarik@arsdigita.com
    @creation-date 22 December 1999

} {
    group_type:notnull
    module_key:notnull
}

set group_type_pretty_name [db_string get_pretty_ugtname "
select pretty_name from user_group_types where group_type=:group_type"]

set page_title "Remove Module"

doc_return  200 text/html "
[ad_admin_header $page_title]
<h2>$page_title</h2>
[ad_admin_context_bar [list "/admin/ug/" "Group Administration"] \
	[list "group-type?group_type=[ns_urlencode $group_type]" "$group_type_pretty_name Administration"] \
	"Confirm Module Removal"]
<hr>
<blockquote>
<h4>Confirm Module Removal</h4>
<table>
<th valign=top>Warning:
<td align=left>Removing module implies that user groups of this type will not be able to use this module.
</table>
<br>Are you sure you want to proceed?
<form method=post action=\"group-type-module-remove-2\">
[export_form_vars group_type module_key]
<input name=confirm_button value=yes type=submit>
[ad_space 5]<input name=confirm_button value=no type=submit>
</form>
</blockquote>
[ad_footer]
"

