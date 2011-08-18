# $Id: group-delete-2.tcl,v 3.0 2000/02/06 03:28:41 ron Exp $
set_the_usual_form_variables

# group_id

set db [ns_db gethandle]

set selection [ns_db 1row $db "select group_name, group_type
from user_groups
where group_id = $group_id"]
set_variables_after_query

ReturnHeaders 

ns_write "[ad_admin_header "Deleting $group_name"]

<h2>Deleting $group_name</h2>

one of <a href=\"index.tcl\">the groups</a> in 
<a href=\"/admin\">[ad_system_name] administration</a> 

<hr>

"

ns_db dml $db "begin transaction"

ns_write "<ul>

<li>Deleting the user-group mappings for groups of this type...

"

# user doesn't really need to hear about this 
ns_db dml $db "delete from user_group_map_queue where group_id = $group_id"

ns_db dml $db "delete from user_group_map where group_id = $group_id"

ns_write "[ns_ora resultrows $db] rows deleted.\n"

ns_write "<li>Deleting group type specific fields... "

ns_db dml $db "delete from [ad_user_group_helper_table_name $group_type] where group_id = $group_id"

ns_write "[ns_ora resultrows $db] rows deleted.\n"

ns_write "<li>Deleting group specific member fields... "

ns_db dml $db "delete from user_group_member_fields where group_id = $group_id"

ns_write "[ns_ora resultrows $db] rows deleted.\n"

ns_write "<li>Deleting group permissions... "

ns_db dml $db "delete from user_group_roles where group_id = $group_id"

ns_write "[ns_ora resultrows $db] rows deleted.\n"

ns_write "<li>Deleting permission mappings... "

ns_db dml $db "delete from user_group_action_role_map where group_id = $group_id"

ns_write "[ns_ora resultrows $db] rows deleted.\n"

ns_write "<li>Deleting group actions... "

ns_db dml $db "delete from user_group_actions where group_id = $group_id"

ns_write "[ns_ora resultrows $db] rows deleted.\n"

ns_write "<li>Deleting $group_name content section links... "

ns_db dml $db "
delete from content_section_links
where from_section_id in (select section_id
                          from content_sections
                          where scope='group'
                          and group_id=$group_id)
or to_section_id in (select section_id
                          from content_sections
                          where scope='group'
                          and group_id=$group_id)
"

ns_write "[ns_ora resultrows $db] rows deleted.\n"

ns_write "<li>Deleting $group_name content section files... "

ns_db dml $db "
delete from content_files
where section_id in (select section_id
                          from content_sections
                          where scope='group'
                          and group_id=$group_id)
"

ns_write "[ns_ora resultrows $db] rows deleted.\n"

ns_write "<li>Deleting $group_name content sections... "

ns_db dml $db "
delete from content_sections
where scope='group'
and group_id=$group_id
"

ns_write "[ns_ora resultrows $db] rows deleted.\n"

ns_write "<li>Deleting $group_name faqs... "

ns_db dml $db "
delete from faqs
where scope='group'
and group_id=$group_id
"

ns_write "[ns_ora resultrows $db] rows deleted.\n"

ns_write "<li>Deleting $group_name logo... "

ns_db dml $db "
delete from page_logos
where scope='group'
and group_id=$group_id
"

ns_write "[ns_ora resultrows $db] rows deleted.\n"

ns_write "<li>Deleting $group_name css... "

ns_db dml $db "
delete from css_simple
where scope='group'
and group_id=$group_id
"
ns_write "[ns_ora resultrows $db] rows deleted.\n"

ns_write "<li>Deleting $group_name downloads ... "

ns_db dml $db "
delete from downloads
where scope='group'
and group_id=$group_id
"
ns_write "[ns_ora resultrows $db] rows deleted.\n"

ns_write "<li>Deleting this group... "

ns_db dml $db "delete from user_groups where group_id = $group_id"

ns_write "[ns_ora resultrows $db] rows deleted.\n"


ns_write "<li>Committing changes...."

ns_db dml $db "end transaction"

ns_write "

</ul>

[ad_admin_footer]
"

