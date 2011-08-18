# $Id: add-complete-css-property.tcl,v 3.0 2000/02/06 03:16:22 ron Exp $
# File:     /admin/diplay/add-complete-css-property.tcl
# Date:     12/26/99
# Author:   ahmeds@arsdigita.com
# Purpose:  adds cascaded style sheet properties
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

set_the_usual_form_variables 0
# maybe return_url
# maybe scope, maybe scope related variables (group_id, user_id)

ad_scope_error_check

ReturnHeaders

set page_title "Add New Property"
set db [ns_db gethandle]

ns_write "
[ad_scope_admin_header $page_title $db]
[ad_scope_admin_page_title $page_title $db]
[ad_scope_admin_context_bar [list "index.tcl?[export_url_scope_vars]" "Display Settings"]  [list "edit-complete-css.tcl?[export_url_scope_vars]" "Edit"] $page_title]
<hr>
"

set css_id [database_to_tcl_string $db  "select css_complete_id_sequence.nextval from dual"]

ns_db releasehandle $db

append html "
<form method=post action=\"add-complete-css-property-2.tcl\">
[export_form_scope_vars return_url selector css_id]

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

ns_write "
<blockquote>
$html
</blockquote>
[ad_scope_admin_footer]
"

