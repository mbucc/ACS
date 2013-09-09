# /www/admin/display/add-complete-css-property.tcl

ad_page_contract {
    adds cascaded style sheet properties
    @param Note: if page is accessed through /groups pages then group_id and group_vars_set 
    are already set up in the environment by the ug_serve_section. group_vars_set 
    contains group related variables (group_id, group_name, group_short_name, 
    group_admin_email, group_public_url, group_admin_url, group_public_root_url,
    group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

    @author ahmeds@arsdigita.com
    @creation-date 12/26/1999

    @cvs-id add-complete-css-property.tcl,v 3.2.2.8 2001/01/10 17:27:32 khy Exp
} {
    selector
    return_url:optional
    scope:optional
    group_id:optional,integer
    user_id:optional,integer    
    group_id:optional,integer
}


ad_scope_error_check

set page_title "Add New Property"

set page_content "
[ad_scope_admin_header $page_title]
[ad_scope_admin_page_title $page_title]
[ad_scope_admin_context_bar [list "index.tcl?[export_url_scope_vars]" "Display Settings"]  [list "edit-complete-css.tcl?[export_url_scope_vars]" "Edit"] $page_title]
<hr>
"

set css_id [db_string "display_sequence_query" "select css_complete_id_sequence.nextval from dual"]

db_release_unused_handles

append html "
<form method=post action=\"add-complete-css-property-2\">
[export_form_scope_vars return_url selector]
[export_form_vars -sign css_id]
<table>

<tr>
<td>Selector 
<td>$selector
</tr>

<tr>
<td>Property
<td><input type=text name=property size=20>[ad_space 5](eg. color)
</tr>

<tr>
<td>Value
<td><input type=text name=value size=20>[ad_space 5](eg. blue)
</tr>

</table>
<p>
<input type=submit value=\"Submit\">
</form>
"

append page_content "
<blockquote>
$html
</blockquote>
[ad_scope_admin_footer]
"

doc_return  200 text/html $page_content






