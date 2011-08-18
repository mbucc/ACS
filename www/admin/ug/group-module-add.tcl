# $Id: group-module-add.tcl,v 3.0 2000/02/06 03:28:54 ron Exp $
# File:     /admin/ug/group-module-add.tcl
# Date:     12/31/99
# Contact:  tarik@arsdigita.com
# Purpose:  adding a module to the group

set_the_usual_form_variables
# group_id

ReturnHeaders 

set page_title "Add Module"

set db [ns_db gethandle]
set group_name [database_to_tcl_string $db "select group_name from user_groups where group_id=$group_id"]
set section_id [database_to_tcl_string $db "select content_section_id_sequence.nextval from dual"]


ns_write "
[ad_admin_header $page_title]
<h2>$page_title</h2>
[ad_admin_context_bar [list "group.tcl?[export_url_vars group_id]" "$group_name"] $page_title]
<hr>
"
set selection [ns_db select $db "
select module_key, pretty_name 
from acs_modules
where supports_scoping_p='t'
and module_key not in (select module_key
                       from content_sections
                       where scope='group' and group_id=$group_id
                       and (section_type='system' or section_type='admin'))"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    
    lappend name_list $pretty_name
    lappend key_list $module_key
}

append html "
<form method=post action=\"group-module-add-2.tcl\"> 
[export_form_vars section_id group_id]
<table>
<tr><th valign=top align=left>Module</th>
<td>[ns_htmlselect -labels $name_list module_key $key_list]</td></tr>
</table>

<p>
<center>
<input type=submit value=\"Add Module\">
</center>
</form>
<p>
"

ns_write "
<blockquote>
$html
</blockquote>
[ad_scope_admin_footer]
"










