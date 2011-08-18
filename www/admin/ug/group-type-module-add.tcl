# $Id: group-type-module-add.tcl,v 3.0 2000/02/06 03:29:19 ron Exp $
# File:     /admin/ug/group-type-module-add.tcl
# Date:     22/12/99
# Contact:  tarik@arsdigita.com
# Purpose:  associates module with the group type

set_the_usual_form_variables
# group_type

ReturnHeaders 

set exception_count 0
set exception_text ""

set db [ns_db gethandle]

set group_type_pretty_name [database_to_tcl_string $db "
select pretty_name as group_type_pretty_name
from user_group_types
where group_type='$QQgroup_type'"]

set group_type_module_id [database_to_tcl_string $db "
select group_type_modules_id_sequence.nextval from dual"]

set selection [ns_db select $db "
select module_key, pretty_name 
from acs_modules
where supports_scoping_p='t'
and module_key not in (select module_key
                       from user_group_type_modules_map
                       where group_type='$QQgroup_type')"]

if { [empty_string_p $selection] } {
    incr exception_count
    append exception_text "
    No modules available for adding. All modules supporting scoping have already been associated with $group_type_pretty_name.
    "
    ad_return_complaint $exception_count $exception_text
    return
}

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    
    lappend module_name_list $pretty_name
    lappend module_key_list $module_key
}

append modules_html "
<tr><th valign=top align=left>Select Module</th>
<td>[ad_space 2] [ns_htmlselect -labels $module_name_list module_key $module_key_list]</td></tr>
"


ns_write "
[ad_admin_header "Add a module to $group_type_pretty_name group type"]
<h2>Add Module</h2>
to the <a href=\"group-type.tcl?[export_url_vars group_type]\">$group_type_pretty_name</a> group type
<hr>
"

append html "
<form action=\"group-type-module-add-2.tcl\" method=post>
[export_form_vars group_type group_type_module_id]
<table>
$modules_html
</table>

<br>
<input type=submit value=\"Add Module\">
</form>
"

ns_write "
<blockquote>
$html
</blockquote>
[ad_admin_footer]
"



