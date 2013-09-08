# /admin/ug/group-module-add.tcl
ad_page_contract {
    Purpose:  adding a module to the group
    @param group_id the ID of the group

    @author tarik@arsdigita.com
    @cvs-id group-module-add.tcl,v 3.2.2.5 2000/09/22 01:36:13 kevin Exp
    @creation-date 31 December 1999
} {
    group_id:notnull,naturalnum
}


set page_title "Add Module"


set group_name [db_string group_name_get "select group_name from user_groups where group_id=:group_id"]
set section_id [db_string get_cs_id_seq "select content_section_id_sequence.nextval from dual"]

set page_html "
[ad_admin_header $page_title]
<h2>$page_title</h2>
[ad_admin_context_bar [list "group?[export_url_vars group_id]" "$group_name"] $page_title]
<hr>
"
db_foreach get_modules_info "
select module_key, pretty_name 
from acs_modules
where supports_scoping_p='t'
and module_key not in (select module_key
                       from content_sections
                       where scope='group' and group_id=:group_id
                       and (section_type='system' or section_type='admin'))" {

    lappend name_list $pretty_name
    lappend key_list $module_key
}

set html "
<form method=post action=\"group-module-add-2\"> 
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

append page_html "
<blockquote>
$html
</blockquote>
[ad_scope_admin_footer]
"

doc_return  200 text/html $page_html