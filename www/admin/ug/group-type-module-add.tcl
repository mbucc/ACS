
#/admin/ug/group-type-module-add.tcl

ad_page_contract {
    associates module with the group type
    @param group_type the type of group

    @author tarik@arsdigita.com
    @creation-date 22 December 1999
    @cvs-id group-type-module-add.tcl,v 3.3.2.5 2000/09/22 01:36:14 kevin Exp
} {
    group_type:notnull
}

set exception_count 0
set exception_text ""



set group_type_pretty_name [db_string get_gt_pretty_name "
select pretty_name as group_type_pretty_name
from user_group_types
where group_type=:group_type"]

db_foreach get_module_key_pretty_names "
select module_key, pretty_name 
from acs_modules
where supports_scoping_p='t'
and module_key not in (select module_key
                       from user_group_type_modules_map
                       where group_type=:group_type)" {
    lappend module_name_list $pretty_name
    lappend module_key_list $module_key
} if_no_rows {
    incr exception_count
    append exception_text "
    No modules available for adding. All modules supporting scoping have already been associated with $group_type_pretty_name.
    "
    ad_return_complaint $exception_count $exception_text
    return
}


append modules_html "
<tr><th valign=top align=left>Select Module</th>
<td>[ad_space 2] [ns_htmlselect -labels $module_name_list module_key $module_key_list]</td></tr>
"

set page_html "
[ad_admin_header "Add a module to $group_type_pretty_name group type"]
<h2>Add Module</h2>
to the <a href=\"group-type?[export_url_vars group_type]\">$group_type_pretty_name</a> group type
<hr>
"

append html "
<form action=\"group-type-module-add-2\" method=post>
[export_form_vars group_type]
<table>
$modules_html
</table>

<br>
<input type=submit value=\"Add Module\">
</form>
"

doc_return  200 text/html  "
$page_html
<blockquote>
$html
</blockquote>
[ad_admin_footer]
"





