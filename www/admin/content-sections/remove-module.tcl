# /www/admin/content-sections/update/remove-module.tcl
ad_page_contract {
    Confirmation page for removing association between module and the group

    Scope aware. Group scope only. Scope related variables are passed implicitly in 
    the local environment and checked with ad_scope_error_check.

    @author tarik@arsdigita.com
    @creation-date 01/01/2000 
    @cvs-id remove-module.tcl,v 3.1.6.5 2000/09/22 01:34:34 kevin Exp

    @param section_key
} {
    section_key:notnull
}

ad_scope_error_check
ad_scope_authorize $scope none group_admin none

set group_name [ns_set get $group_vars_set group_name]

set page_title "Remove Module"

doc_return  200 text/html "
[ad_scope_admin_header $page_title]
[ad_scope_admin_page_title $page_title]
[ad_scope_admin_context_bar [list "index" "Content Sections"] $page_title]
<hr>
<blockquote>
<h4>Confirm Module Removal</h4>
<table>
<th valign=top>Warning:
<td align=left>Removing module implies that users of $group_name will not be able to use this module.
</table>
<br>Are you sure you want to proceed ?
<form method=post action=\"remove-module-2\">
[export_form_vars section_key]
<input name=confirm_button value=yes type=submit>
[ad_space 5]<input name=confirm_button value=no type=submit>
</form>
</blockquote>
[ad_scope_footer]
"

